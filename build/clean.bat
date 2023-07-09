cd..
for /d /r . %%d in (bin,obj,packages,.tmp,.vs) do @if exist "%%d" rd /s/q "%%d"