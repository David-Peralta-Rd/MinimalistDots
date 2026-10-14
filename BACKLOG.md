# 🐧 MinimalistDots: Backlog & Gestión de Alcance

Este documento define la hoja de ruta de la configuración. Cada decisión se rige bajo el principio: **"Menos es más. Si no es estrictamente necesario, no se incluye".**

---

## 🟢 1. En Desarrollo / Próximo (Lo que SÍ se va a hacer)
*Características esenciales para un entorno de trabajo funcional, rápido y estético.*

- [-] **Menus (Migración)**: Reemplazar por completo todos los menús e interfaces antiguas de `wofi` y `eww` por componentes nativos y ultra-ligeros usando `quickshell`.

---

## 🟡 2. El "Icebox" (Lo que podría hacerse en el momento adecuado)
*Ideas interesantes que están en pausa porque añaden complejidad visual o de mantenimiento en esta etapa.*

- [ ] **Feat-01**: Optimización e indicadores específicos para Laptops (Gestión de batería, brillo de pantalla, estados de suspensión eficientes). *Estado: Postergado para mantener el desarrollo centrado en el core del sistema de escritorio.*
- [ ] **Feat-02**: Script de cambio automático entre Modo Claro y Oscuro según la hora. *Estado: Postergado para evitar demonios (daemons) en segundo plano.*
- [ ] **Feat-03**: Integración de notificaciones ligeras a través de la terminal o demonios ultra-ligeros (`mako` o `dunst`). *Estado: Evaluando si rompe la estética limpia.*

---

## ❌ 3. Fuera de Alcance (Lo que NO se va a hacer)
*Decisiones firmes de descarte para proteger la filosofía minimalista del proyecto y evitar el "bloatware".*

- ❌ **Soporte para X11 o Gestores antiguos (bspwm / i3wm)**
  - *Razón:* El proyecto migró formalmente a Hyprland. Mantener configuraciones duplicadas para servidores gráficos obsoletos ensucia el repositorio.
- ❌ **Múltiples entornos de escritorio (GNOME, KDE, XFCE)**
  - *Razón:* El proyecto está diseñado exclusivamente para *Window Managers* independientes. Soportar escritorios completos rompe el propósito de ligereza.
- ❌ **Configuración de barras de estado (Waybar / Polybar)**
  - *Razón:* MinimalistDots será limpio visualmente y no se le agregarán barras de menús que ocupen espacio vertical u horizontal en la pantalla. Todo se gestiona por atajos.
- ❌ **Scripts de automatización de respaldos en la nube (Rclone/Mega/Drive)**
  - *Razón:* El manejo de datos personales y credenciales debe ser gestionado por el usuario. Añadirlo incrementa el riesgo de seguridad y el peso de los dotfiles.
- ❌ **Instalador interactivo con interfaz gráfica (GUI)**
  - *Razón:* Un usuario de dotfiles minimalistas debe estar cómodo con la terminal. El instalador se mantendrá como un script de bash simple y legible (`.sh`).
- ❌ **Inclusión de múltiples temas de colores (Dracula, Gruvbox, Nord, etc.)**
  - *Razón:* MinimalistDots se distribuirá con **un solo tema oficial** bien pulido. Ofrecer variantes satura el repositorio; el usuario puede cambiar los colores manualmente si lo desea.

---

## 🛡️ Filtro de Admisión: ¿Cómo decidimos?
Para que una nueva idea sea aprobada en la Sección 1, debe responder **SÍ** a estas tres preguntas:
1. ¿El entorno puede seguir funcionando perfectamente sin esto? (Si la respuesta es sí, se va al Icebox o se descarta).
2. ¿Consume menos de 5MB de espacio y recursos mínimos de CPU/RAM?
3. ¿Requiere configuraciones adicionales que el usuario tenga que mantener de forma manual?
