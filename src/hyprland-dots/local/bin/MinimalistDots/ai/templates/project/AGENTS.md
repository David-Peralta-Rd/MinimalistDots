# AGENTS.md — __PROJECT__

## Proyecto
<una línea: qué es y para quién>

## Stack
<lenguaje, framework, base de datos y versión de cada uno>

## Comandos
- Instalar: <comando>
- Test: <comando>
- Lint y tipos: <comando>
- Levantar local: `docker compose up`

## Convenciones
- Commits convencionales; una tarea por rama.
- Toda función nueva trae su test en el mismo cambio.
- Nada de lógica de negocio en los controladores/rutas: va en servicios.

## Estilo (Python; borra esta sección si el proyecto no lo es)
- Responde en español; código conciso, sin explicaciones largas salvo que se pidan.
- Type hints completos (parámetros, retornos incluido `-> None`, variables no obvias); que pase Pylance en modo strict. Nada de `Any` salvo necesidad, con un comentario corto del porqué.
- Genéricos de `typing` modernos (`list[str]`, `dict[str, int]`); dataclasses o Pydantic en vez de diccionarios sueltos.
- Nombres explícitos; `pathlib.Path` en vez de `os.path`.
- Tests con pytest (funciones `test_*`, fixtures), nunca `unittest.TestCase`.
- Sigue el estilo del archivo abierto; no reformatees lo que no te pedí tocar.

## Nunca
- Tocar migraciones ya aplicadas, secretos o archivos `.env`.
- Instalar dependencias sin explicar por qué.
- Cambiar autenticación, permisos o manejo de pagos sin que la tarea esté marcada [YO] y revisada por el humano.

## Cómo trabajas
1. Lee `SPEC.md` y `tasks.md`.
2. Trabaja UNA tarea marcada [DELEGAR]; propón un plan corto antes de escribir código.
3. Corre tests, linter y tipos.
4. Muestra el diff y explica qué cambió y por qué. No hagas commit sin revisión.
