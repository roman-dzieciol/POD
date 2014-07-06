::
:: Environment
::
@SET MOD_NAME=POD
@SET MOD_SYS=..\..\%MOD_NAME%\System
@SET MOD_HELP=If you need assistance please contact us.
@SET MOD_URL=http://mods.moddb.com/7798/pod/

@ECHO // ---------------------------------------------------------------------------
@ECHO // UCL Exporter for %MOD_NAME%.
@ECHO // ---------------------------------------------------------------------------

CD %MOD_SYS%
@if ERRORLEVEL 1 GOTO FAILURE

FOR %%a IN (*.u) DO START /B /WAIT ..\..\System\ucc.exe engine.exportcache  %%a -mod=%MOD_NAME%
@if ERRORLEVEL 1 GOTO FAILURE


::
:: Success 
::
@GOTO FINISH

::
:: Something's wrong
::
:FAILURE
@COLOR 4F
@ECHO.
@ECHO.
@ECHO !!! ERROR !!!
@ECHO.
@ECHO %MOD_HELP%
@ECHO %MOD_URL%
@ECHO.
@PAUSE
@COLOR


:FINISH