@ECHO OFF
@SET MOD_NAME=POD
@SET MOD_GAME=POD.PODGame

::
:: Edit those three lines below to change the map, mutators and other options
::
@SET MOD_MAP=DM-POD-Knot
@SET MOD_MUTATOR=
@SET MOD_OPTIONS=

@COPY /Y System\Dedicated.log System\Dedicated.old.log
..\System\ut2004.exe %MOD_MAP%?game=%MOD_GAME%?mutator=%MOD_MUTATOR%%MOD_OPTIONS% -server -MOD=%MOD_NAME% -LOG=..\%MOD_NAME%\System\Dedicated.log
