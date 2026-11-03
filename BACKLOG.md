# 🐧 MinimalistDots: Backlog & Gestión de Alcance

Este documento define la hoja de ruta de la configuración. Cada decisión se rige bajo el principio: **"Menos es más. Si no es estrictamente necesario, no se incluye".**

---

## 🟢 1. En Desarrollo / Próximo (Lo que SÍ se va a hacer)
*Características esenciales para un entorno de trabajo funcional, rápido y estético.*

- [-] **Análisis de arquitectura del proyecto (organización de carpetas, archivos y configuración)**: `Revisar:` Si el proyecto sigue siendo escalable, las configuraciones están divididas?, los archivos de Quickshell son **demasiados**?, vale la pena dividir por subcategorias las secciones de scripts y Quickshell?, Agregar a cada apartado de configuración un archivo maestro que se conecte a todo por cada apartado?

- [-] **Implementación de selector de lenguajes (Configurar cada script para que tenga diálogos en diferentes lenguajes)**: `Agregar:` La idea principal es que cada script como portapapeles, llm_menu, notificaciones, etc. Sus diálogos puedan ser variables para configurar un selector de idioma. Este selector debe ser usado con cache o memoria, solo aplicara cambios en los reinicio del equipo (*se podría considerar crearle un servicio.lua*), debe funcionar en terminal y como interfaz en Quickshell. Lo importante es que no sea un proceso que se mantenga todo el tiempo activo o que funcione en tiempo real.

- [-] **Hacer escalable la selección de idiomas del proyecto (configurar: "src/setup/lang/load_lang.sh")**: `Optimización:` Se busca que **load_lang.sh** pueda analizar los lenguajes dentro de *"src/setup/lang/options"* y mostrarlos de manera automática, sin necesidad de modificaciones manuales en el script, teniendo una capacidad de mostrar 7 lenguajes en un script interactivo con buscador para facilitar la búsqueda de un lenguaje. **Idea principal:**
  - Poder agregar lenguajes que tengan estas iniciales en su nombre: lg1_NOMBRE_DEL_IDIOMA-(SIGLAS_DEL_IDIOMA), ejemplo: lg1_Colombia_Spanish-(es-co). Asi con cada idioma.
  - El script de "load_lang.sh" debe ser capaz de leer todos los archivos con estas iniciales y mostrarlos en orden numerados sin el "lgN_", esto se hará asi para que sea fácil agregar idiomas y que el script los lea sin necesidad de modificarlo manualmente.
  - El script de "load_lang.sh" debe tener el buscador basándose en las siglas o el nombre del idioma.


- [-] **Nuevo scrip llamado "bk9_language_selector.sh" (Dentro de: "src/setup/scripts/components/c4_backup_scripts")**: `Uso principal:` Esto va a estar conectado con la **Implementación de selector de lenguajes"**, lo que hará este script es dentro de "~/.local/bin/MinimalistDots" una carpeta llamada "language_options", crear todos los archivos de lenguaje para el Quickshell o script de terminal usado, la idea es que esto sea escalable y cualquier persona pueda agregar un nuevo idioma configurando las variables de los archivos y traduciendo los diálogos(Nota importante: Los nombres de las variables de estos archivos serán en español, esto se hará asi para que el autor del proyecto **David Peralta** pueda construir y escalar el proyecto rápidamente, los dialogs dentro de esas variables si ya serán correspondientes al idioma que se desee tener.)
**Pasos necesarios para que esto funcione:**
  1. - Agregar la carpeta de "language_options" al script de creación de carpetas: **"src/setup/scripts/components/c1_new_folders.sh"**.
  2. - Crear el Quickshell dentro del script: **"src/setup/script/components/c4_backups_scripts/bk3_quickshell.sh"** *(Nota importante: Esta ubicación puede cambiar si en la configuración de arquitectura se divide la creación de los menus Quickshell)*.
  3. - Medir si es necesario tener configuraciones dentro de: **"src/setup/scripts/utils/u3_env.sh"**.

- [-] **Configuración del estilo definitivo (Marca de MinimalistDots y configuraciones visuales)**: `Construir:` Crear una identidad visual del MinimalistDots, para asi asegurarnos que todos los menus y estilos de configuración sigan el mismo modelo visual.

`Problema que resuelve:` Algunos menus quickshell o servicios tienen estilo de minimalismo, conservando los colores de MinimalistDots, pero llevando un estilo de minimalismo divido, que no es feo, pero puede ser mejor y tener una identidad única.

---

## 🟡 2. El "Icebox" (Lo que podría hacerse en el momento adecuado)
*Ideas interesantes que están en pausa porque añaden complejidad visual o de mantenimiento en esta etapa.*

- [ ] **Feat-01**: Optimización e indicadores específicos para Laptops (Gestión de batería, brillo de pantalla, estados de suspensión eficientes). *Estado: Postergado para mantener el desarrollo centrado en el core del sistema de escritorio.*
- [ ] **Feat-02**: Script de cambio automático entre Modo Claro y Oscuro según la hora. *Estado: Postergado para evitar demonios (daemons) en segundo plano.*

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
