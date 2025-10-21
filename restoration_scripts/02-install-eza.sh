#!/usr/bin/env bash
#
# Script de restauración que instala el comando 'eza' (o 'exa' como fallback)
# usando 'cargo' o el gestor de paquetes nativo (apt/dnf)
#
# Eza es un reemplazo moderno del comando 'ls' escrito en Rust.
# Si 'cargo' (el gestor de paquetes de Rust) está instalado, se utiliza para obtener la última versión.
# De lo contrario, se intenta usar apt (Debian/Ubuntu) o dnf (Fedora/RHEL).

set -euo pipefail

# --- Colores para la salida ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# --- 1. Verificar si Eza/Exa ya está instalado ---
if command -v eza &> /dev/null; then
    log_info "eza ya está instalado. Saliendo."
    exit 0
fi

if command -v exa &> /dev/null; then
    log_info "exa (la versión anterior) ya está instalado. Si deseas actualizar a eza, desinstala exa y ejecuta el script de nuevo."
    exit 0
fi

log_info "eza o exa no encontrados. Procediendo a la instalación..."

# --- 2. Intento de instalación con Cargo (Opción Universal y Preferida) ---
if command -v cargo &> /dev/null; then
    log_info "Cargo (gestor de paquetes de Rust) encontrado. Instalando eza mediante cargo..."
    
    # Intenta instalar 'eza'
    if cargo install eza; then
        log_info "eza instalado exitosamente con Cargo."
        log_info "Asegúrate de que \$HOME/.cargo/bin esté en tu \$PATH."
        exit 0
    else
        log_error "Fallo al instalar eza con Cargo. Intentando con gestor de paquetes..."
    fi
fi

# --- 3. Instalación específica de distribución (Fallback) ---

# Detectar el gestor de paquetes
if command -v dnf &> /dev/null; then
    # Fedora, RHEL, CentOS (usando dnf)
    log_info "Distribución basada en DNF detectada (Fedora, etc.)."
    
    # Nota: Fedora ya tiene 'eza' en sus repositorios para versiones recientes.
    # Si no estuviera, se podría usar 'exa'.
    PACKAGE_TO_INSTALL="eza"

    log_info "Intentando instalar ${PACKAGE_TO_INSTALL} con dnf..."
    if sudo dnf install -y "${PACKAGE_TO_INSTALL}"; then
        log_info "${PACKAGE_TO_INSTALL} instalado exitosamente con dnf."
        exit 0
    else
        log_warn "Fallo al instalar ${PACKAGE_TO_INSTALL} con dnf. Probando con exa..."
        PACKAGE_TO_INSTALL="exa"
        if sudo dnf install -y "${PACKAGE_TO_INSTALL}"; then
            log_info "exa instalado exitosamente con dnf."
            exit 0
        fi
    fi

elif command -v apt &> /dev/null; then
    # Debian, Ubuntu, Mint (usando apt)
    log_info "Distribución basada en APT detectada (Debian, Ubuntu, etc.)."
    
    # 'eza' no está universalmente disponible en APT, pero 'exa' sí en muchas versiones.
    PACKAGE_TO_INSTALL="exa" 

    log_info "Intentando instalar ${PACKAGE_TO_INSTALL} con apt..."
    
    # Actualizar la lista de paquetes por si acaso (necesario antes de instalar)
    if sudo apt update; then
        if sudo apt install -y "${PACKAGE_TO_INSTALL}"; then
            log_info "${PACKAGE_TO_INSTALL} instalado exitosamente con apt."
            exit 0
        else
            log_error "Fallo al instalar ${PACKAGE_TO_INSTALL} con apt. Es posible que el paquete no esté disponible en tu versión de SO."
        fi
    else
        log_error "Fallo al ejecutar 'sudo apt update'. Verifica permisos o la configuración de red."
    fi

else
    # Si no se reconoce el gestor de paquetes
    log_error "No se pudo determinar el gestor de paquetes (apt o dnf no encontrados)."
fi


# --- 4. Conclusión de Fallo ---
log_error "================================================================="
log_error "FALLO DE INSTALACIÓN"
log_error "No se pudo instalar eza o exa automáticamente."
log_error "Intenta instalar 'eza' manualmente o asegúrate de tener 'cargo' instalado."
log_error "================================================================="
exit 1
