@ECHO OFF
SET MOD_NAME=POD
SET MOD_GAME=POD.PODGame

::
:: Edit those three lines below to change the map, mutators and other options
::
SET MOD_MAP=DM-POD-Tiny
SET MOD_MUTATOR=
SET MOD_OPTIONS=?SpectatorOnly=False?bAutoNumBots=False?VsBots=False?NumBots=0

COPY /Y System\%MOD_NAME%.log System\%MOD_NAME%.old.log
START ..\System\UT2004.exe %MOD_MAP%?game=%MOD_GAME%?mutator=%MOD_MUTATOR%%MOD_OPTIONS% -makenames -windowed -log -MOD=%MOD_NAME%
