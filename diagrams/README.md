# Diagrams

This folder contains Mermaid use-case diagrams for your presentation.

Files:
- `passenger_use_case.mmd`
- `driver_use_case.mmd`
- `admin_use_case.mmd`

## Render to SVG/PNG (PowerShell)

1. Install Mermaid CLI:
```powershell
npm i -g @mermaid-js/mermaid-cli
```
2. Run the script:
```powershell
./render.ps1
```
Outputs SVG files into `diagrams/out/`.

## Manual commands
```powershell
mmdc -i .\passenger_use_case.mmd -o .\out\passenger_use_case.svg
mmdc -i .\driver_use_case.mmd -o .\out\driver_use_case.svg
mmdc -i .\admin_use_case.mmd -o .\out\admin_use_case.svg
```
