# Directrices para Mensajes de Commit

<!--
Soporte multilingüe para COMMIT_MESSAGE_GUIDELINES
-->

[![en](https://img.shields.io/badge/lang-en-red.svg)](../../COMMIT_MESSAGE_GUIDELINES.md)
[![de](https://img.shields.io/badge/lang-de-black.svg)](COMMIT_MESSAGE_GUIDELINES.de.md)
[![fr](https://img.shields.io/badge/lang-fr-blue.svg)](COMMIT_MESSAGE_GUIDELINES.fr.md)

Un buen mensaje de commit debe ser descriptivo y proporcionar contexto sobre los cambios realizados. Esto facilita la comprensión y revisión de los cambios en el futuro.

Aquí hay algunas directrices para escribir mensajes de commit descriptivos:

- Comienza con un resumen breve de los cambios realizados en el commit.

- Usa el modo imperativo para el resumen, como si estuvieras dando una orden. Por ejemplo, "Añadir funcionalidad" en lugar de "Añadida funcionalidad".

- Proporciona detalles adicionales en el cuerpo del mensaje del commit, si es necesario. Esto podría incluir la razón del cambio, el impacto del cambio o cualquier dependencia que se haya introducido o eliminado.

- Mantén el mensaje dentro de 72 caracteres por línea para asegurarte de que sea fácil de leer en la salida del registro de Git.

Ejemplos de buenos mensajes de commit:

- "Añadir funcionalidad de autenticación para inicio de sesión de usuarios"
- "Corregir error que causaba que la aplicación se cerrara al iniciar"
- "Actualizar documentación para los endpoints de la API"

Recuerda, escribir mensajes de commit descriptivos puede ahorrar tiempo y frustración en el futuro, y ayudar a otros a entender los cambios realizados en el código.

## Tipos de Mensajes de Commit

Aquí tienes una lista más completa de tipos de commit que puedes usar:

`feat`: Añadir una nueva funcionalidad al proyecto

```markdown
feat: Añadir soporte para carga de múltiples imágenes
```

`fix`: Corregir un error o problema en el proyecto

```markdown
fix: Corregir error que causaba que la aplicación se cerrara al iniciar
```

`docs`: Actualizar la documentación del proyecto

```markdown
docs: Actualizar documentación para los endpoints de la API
```

`style`: Realizar cambios cosméticos o de estilo en el proyecto (como cambiar colores o formatear código)

```markdown
style: Actualizar colores y formato
```

`refactor`: Realizar cambios en el código que no afectan el comportamiento del proyecto, pero mejoran su calidad o mantenibilidad

```markdown
refactor: Eliminar código no utilizado
```

`test`: Añadir o modificar pruebas para el proyecto

```markdown
test: Añadir pruebas para nueva funcionalidad
```

`chore`: Realizar cambios en el proyecto que no encajan en ninguna otra categoría, como actualizar dependencias o configurar el sistema de compilación

```markdown
chore: Actualizar dependencias
```

`perf`: Mejorar el rendimiento del proyecto

```markdown
perf: Mejorar rendimiento del procesamiento de imágenes
```

`security`: Abordar problemas de seguridad en el proyecto

```markdown
security: Actualizar dependencias para abordar problemas de seguridad
```

`merge`: Fusionar ramas en el proyecto

```markdown
merge: Fusionar rama 'feature/nombre-de-la-rama' en develop
```

`revert`: Revertir un commit anterior

```markdown
revert: Revertir "Añadir funcionalidad"
```

`build`: Realizar cambios en el sistema de compilación o dependencias del proyecto

```markdown
build: Actualizar dependencias
```

`ci`: Realizar cambios en el sistema de integración continua (CI) del proyecto

```markdown
ci: Actualizar configuración de CI
```

`config`: Realizar cambios en los archivos de configuración del proyecto

```markdown
config: Actualizar archivos de configuración
```

`deploy`: Realizar cambios en el proceso de despliegue del proyecto

```markdown
deploy: Actualizar scripts de despliegue
```

`init`: Crear o inicializar un nuevo repositorio o proyecto

```markdown
init: Inicializar proyecto
```

`move`: Mover archivos o directorios dentro del proyecto

```markdown
move: Mover archivos a un nuevo directorio
```

`rename`: Renombrar archivos o directorios dentro del proyecto

```markdown
rename: Renombrar archivos
```

`remove`: Eliminar archivos o directorios del proyecto

```markdown
remove: Eliminar archivos
```

`update`: Actualizar código, dependencias u otros componentes del proyecto

```markdown
update: Actualizar código
```

Estos son solo algunos ejemplos, y también puedes crear tus propios tipos de commit personalizados. Sin embargo, es importante usarlos de manera consistente y escribir mensajes de commit claros y descriptivos para facilitar que otros comprendan los cambios que has realizado.

**Importante:** Si planeas usar un tipo de mensaje de commit personalizado que no esté en la lista anterior, asegúrate de añadirlo a esta lista para que otros puedan entenderlo también. Crea un pull request para añadirlo a este archivo.

