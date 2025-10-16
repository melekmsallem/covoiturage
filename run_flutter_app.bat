@echo off
echo ========================================
echo   Covoiturage Flutter App Launcher
echo ========================================
echo.
echo Backend should be running on: http://localhost:8081
echo.
echo Checking Flutter installation...
flutter doctor --version
echo.
echo Installing dependencies...
cd covoiturage_app
call flutter pub get
echo.
echo Launching Flutter app on Chrome...
echo.
echo Available commands during run:
echo   r - Hot reload
echo   R - Hot restart
echo   q - Quit
echo.
start /B flutter run -d chrome
echo.
echo Flutter app is launching...
echo Check Chrome browser window
echo.
pause


















