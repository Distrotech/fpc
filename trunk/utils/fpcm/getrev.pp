
program getrev;

{ The purpose of this program is to
  parse the output of svn info several files
  and to extract the lastest date and revision

  The program expects a single parameter,
  being the name of the text file }

procedure Usage;
begin
  Writeln(paramstr(0),' requires exactly one parameter');
  Writeln('This paramaeter must be the name of the file');
  Writeln('Generated by svn info files > filename');
  halt(1);
end;

var
  filename, fileurl, line, date, lastdate,
  revision, oldrevstring, olddate : string;
  f : text;
  p, io : longint;
  rev, lastrev, oldrev : longint;

begin
  if paramcount<>1 then
    Usage;
  filename:=paramstr(1);
{$i-}
  assign(f,filename);
  reset(f);
  io:=ioresult;
  if io<>0 then
    begin
      Writeln('Unable to open ',filename,' for reading, io=',io);
      halt(2);
    end;
  lastrev:=0;
  lastdate:='0';
  while not eof(f) do
    begin
      readln(f,line);
      p:=pos('URL: ',line);
      if p>0 then
        begin
          fileurl:=copy(line,p+length('URL: '),length(line));
          writeln('fileurl=',fileurl);
        end;
      p:=pos('Last Changed Date: ',line);
      if p>0 then
        begin
          date:=copy(line,p+length('Last Changed Date: '),length(line));
          p:=pos(' ',date);
          if p>0 then
            date:=copy(date,1,p-1);
          writeln('date=',date);
          if date>lastdate then
            lastdate:=date;
        end;
      p:=pos('Last Changed Rev: ',line);
      if p>0 then
        begin
          revision:=copy(line,p+length('Last Changed Rev: '),length(line));
          writeln('rev=',revision);
          val(revision,rev);
          if rev>lastrev then
            lastrev:=rev;
        end;
    end;
  close(f);
  assign(f,'revision.inc');
  io:=ioresult;
  reset(f);
  io:=ioresult;
  if io<>0 then
    begin
      Writeln('revision.inc reset failed, io=',io);
    end
  else
    begin
      readln(f,oldrevstring);
      close(f);
      writeln('oldrevstring ',oldrevstring);
      if oldrevstring[1]='''' then
        oldrevstring:=copy(oldrevstring,2,length(oldrevstring));
      p:=length(oldrevstring);
      if oldrevstring[p]='''' then
        oldrevstring:=copy(oldrevstring,1,p-1);
      p:=pos(' rev ',oldrevstring);
      if p>0 then
        begin
          val(copy(oldrevstring,p+5,length(oldrevstring)),oldrev);
          olddate:=copy(oldrevstring,1,p-1);
          Writeln('Old values ',olddate,' ',oldrev);
          if (olddate >= lastdate) and (oldrev >= lastrev) then
            begin
              Writeln('New values ',lastdate,' ',lastrev);
              Writeln('Keeing old values');
              lastrev:=oldrev;
              lastdate:=olddate;
            end;
        end;

    end;

  Writeln('revision.inc set to ''',lastdate,' rev ',lastrev,'''');

  assign(f,'revision.inc');
  rewrite(f);
  io:=ioresult;
  if io <> 0 then
    begin
      Writeln('Error opening revision.inc for writing');
      halt(3);
    end;
  Writeln(f,'''',lastdate,' rev ',lastrev,'''');
  close(f);
end.


