# Panel de INPROYECT

La aplicación actual se encuentra en `app/` y apunta al proyecto Firebase
`inproyect-24922`. Abrir `InProject.code-workspace` desde la raíz del repositorio
selecciona esta carpeta en VS Code. La copia antigua de la raíz no se ha eliminado.

## Entrega del 23 de noviembre de 2026

- Inicio con seis rubros del tablero actualizado de cliente y colores azul/naranja.
- Navegación a la descripción de cada rubro y regreso al inicio.
- Secciones separadas de proyectos, billetera y ayuda; preguntas desplegables.
- Mensaje de error de perfil si Firestore rechaza el acceso.

Proyectos y billetera muestran su estado pendiente. No se han añadido publicaciones,
postulaciones, saldos, recargas, pagos ni resultados ficticios a Firestore.
La ubicación y los proyectos activos del mockup se incorporarán al tener sus datos reales.

El login, registro y perfil del compañero permanecen sin cambios. La nueva definición
de los roles debe confirmarse con el equipo antes de implementar sus acciones.

## Cómo revisar

En VS Code ejecutar `InProject · Firebase nuevo` para el flujo de autenticación real.
Para revisar únicamente el diseño sin depender del login, ejecutar
`InProject · Vista previa del panel` (`lib/main_preview.dart`). Esta opción muestra
un aviso permanente y no inicia Firebase ni representa a un usuario autenticado.

La restricción de Dart se ajustó a `>=3.13.7 <4.0.0` para el SDK instalado en la laptop.

## Respaldo

El avance anterior está en el stash de Git titulado
`Respaldo recorridos locales antes de integrar version 79b4439 - 2026-11-23`.
La rama anterior `desarrollo/recorridos-locales` se conserva.
No aplicar ese stash directamente sobre la nueva versión: recuperar e integrar los
archivos necesarios por separado cuando se retome el recorrido de requerimientos.
