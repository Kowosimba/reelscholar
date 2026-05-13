$src = "c:\Users\Administrator\Documents\Essential Projects\reelscholar\Code files"
$dst = "c:\Users\Administrator\Documents\Essential Projects\reel_scholar_mobile_app\lib"

# Ensure directories exist
$dirs = @(
    "$dst\core\constants",
    "$dst\core\theme",
    "$dst\core\navigation",
    "$dst\providers",
    "$dst\services",
    "$dst\widgets",
    "$dst\screens\auth",
    "$dst\screens\onboarding",
    "$dst\screens\splash",
    "$dst\screens\reels\widgets",
    "$dst\models",
    "$dst\screens\modules\widgets",
    "$dst\screens\messaging",
    "$dst\screens\notifications"
)
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

# Files 1
Copy-Item "$src\files (1)\api_constants.dart" -Destination "$dst\core\constants\" -Force
Copy-Item "$src\files (1)\app_colors.dart" -Destination "$dst\core\theme\" -Force
Copy-Item "$src\files (1)\app_theme.dart" -Destination "$dst\core\theme\" -Force
Copy-Item "$src\files (1)\auth_provider.dart" -Destination "$dst\providers\" -Force
Copy-Item "$src\files (1)\auth_service.dart" -Destination "$dst\services\" -Force
Copy-Item "$src\files (1)\auth_widgets.dart" -Destination "$dst\widgets\" -Force
Copy-Item "$src\files (1)\*screen.dart" -Destination "$dst\screens\auth\" -Force
Move-Item "$dst\screens\auth\onboarding_screen.dart" -Destination "$dst\screens\onboarding\" -Force
Move-Item "$dst\screens\auth\splash_screen.dart" -Destination "$dst\screens\splash\" -Force

# Files 2
Copy-Item "$src\files (2)\*screen.dart" -Destination "$dst\screens\reels\" -Force
Copy-Item "$src\files (2)\user_reels_tab.dart" -Destination "$dst\screens\reels\" -Force
Copy-Item "$src\files (2)\comments_sheet.dart" -Destination "$dst\screens\reels\widgets\" -Force
Copy-Item "$src\files (2)\reel_player_item.dart" -Destination "$dst\screens\reels\widgets\" -Force
Copy-Item "$src\files (2)\reel_widgets.dart" -Destination "$dst\screens\reels\widgets\" -Force
Copy-Item "$src\files (2)\navigation_provider.dart" -Destination "$dst\providers\" -Force
Copy-Item "$src\files (2)\reel_models.dart" -Destination "$dst\models\" -Force
Copy-Item "$src\files (2)\reel_provider.dart" -Destination "$dst\providers\" -Force
Copy-Item "$src\files (2)\reel_service.dart" -Destination "$dst\services\" -Force

# Files 3
Copy-Item "$src\files (3)\*screen.dart" -Destination "$dst\screens\modules\" -Force
Copy-Item "$src\files (3)\tutor_models.dart" -Destination "$dst\models\" -Force
Copy-Item "$src\files (3)\tutor_provider.dart" -Destination "$dst\providers\" -Force
Copy-Item "$src\files (3)\tutor_service.dart" -Destination "$dst\services\" -Force
Copy-Item "$src\files (3)\tutor_widgets.dart" -Destination "$dst\screens\modules\widgets\" -Force

# Files 4
Copy-Item "$src\files (4)\app_bottom_nav_bar.dart" -Destination "$dst\core\navigation\" -Force
Copy-Item "$src\files (4)\app_drawer.dart" -Destination "$dst\core\navigation\" -Force
Copy-Item "$src\files (4)\app_router.dart" -Destination "$dst\core\navigation\" -Force
Copy-Item "$src\files (4)\chats_screen.dart" -Destination "$dst\screens\messaging\" -Force
Copy-Item "$src\files (4)\notifications_screen.dart" -Destination "$dst\screens\notifications\" -Force
Copy-Item "$src\files (4)\main.dart" -Destination "$dst\" -Force
Copy-Item "$src\files (4)\main_screen.dart" -Destination "$dst\screens\main_screen.dart" -Force

Write-Host "Copy operation completed successfully."
