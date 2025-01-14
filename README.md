# seat-control

Sistema de control de un asiento de automóvil para una FPGA ([DE0-Nano][2])

## 📋 Índice

- ❔ [¿Qué es?](#-qúe-es)
- 🔨 [Build](#-build)
- 🖥️ [Prueba del sistema](#️-prueba-del-sistema)
- 📜 [Licencia](#-licencia)
- 🔧 [Posibles mejoras](#-posibles-mejoras)

## ❔ ¿Qúe es?

Este proyecto intenta recrear el funcionamiento de un asiento de automóvil con memoria y control de posición para el respaldo y la banqueta de este. Se ha desorrado como el proyecto final de una asignatura dedicada al diseño e implementación de sistemas digitales, como pueden ser las FPGAs.

El propósito principal fue el de aprender cómo se desarrolla código para un dispositivo externo a la máquina con la que programamos, como puede ser una FPGA o un microcontrolador. Además de ello, aprender cómo funcionan estos dispositivos y las ventajas y desventajas que proporcionan, además de sus limitaciones a la hora de usarse en el mundo real.

El sistema permite realizar las siguientes acciones:

- Subir y bajar el respaldo / banqueta del asiento.
- Función de memorización y recuperación de hasta dos posiciones definidas por el usuario del respaldo y la banqueta.
- Límites por software y hardware configurables de lo mucho que se pueden mover los motores.
- Función que calibración para establecer los límites de movimiento.
- LEDs indicadores de estado.

---

Placa para la que se realizó el programa ([DE0-Nano][2]):

<div style="display: flex; gap: 1%">
    <img src="./media/fpga_off.jpg" alt="FPGA_1" style="width: 49.5%">
    <img src="./media/fpga_on.jpg" alt="FPGA_2" style="width: 49.5%">
</div>

## 🔨 Build

Los requisitos para poder correr este programa serán:

- [Git](https://git-scm.com/downloads)
- [Quartus II][1] (version 18.1 o superior)

> 📝**Nota:** La estructura este repositorio es méramente demostrativa, organizando el código en dos directorios, `src` para el código fuente y `test` para el código de pruebas del sistema. Estos archivos son redundandes puesto que vienen incluidos dentro del fichero `seat-control.qar`, el cual actua como archivo comprimido de un proyecto para el programa [Quartus II][1].

El primer paso será clonar este repositorio mediante el siguiente comando:

```bash
git clone https://github.com/dtx1007/seat-control
cd seat-control
```

El proyecto está empaquetado dentro del fichero `seat-control.qar`, lo único que hay que hacer es abrir el programa [Quartus II][1] e importar dicho proyecto mediante la opción del menú del programa `Project > Restore Archived Project...`, la cual nos preguntará por la ruta del archivo `seat-control.qar` y una ruta donde guardar el proyecto que se creará.

Una vez el proyecto termine de crearse, simplemente será necesario compilar el mismo pulsado `Ctrl + L` o usando el botón de la interfaz.

## 🖥️ Prueba del sistema

Existen dos formas de probar el sistema, sobre el hardware real o mediante una simulación.

### Sobre hardware real

La placa sobre la cual se ha ejecutado este programa es una [DE0-Nano][2], la cual contiene una FPGA Cyclon IV de Altera.

Para cargar el programa dentro de la placa, lo que debemos hacer es abrir la herramienta del programador que incluye [Quartus II][1] en su menú de programa `Tools > Programmer`. Al iniar esta herramienta será necesario conectar la placa a nustro equipo para que esta sea detectada, una vez ocurra esto, simplemente se ha de pulsar el botón `Start` y el proceso de carga se realizará automáticamente.

Con fines didácticos, en vez de conectar la placa directamente a otros componentes como podrían ser motores o encoders, para comprobar el funcionamiento correcto de esta, se utilizó una placa de interruptores adicional que simulaba los compoenentes externos que podrían llegar a conectarse.

---

Placa de interruptores:

![Switch board](./media/switch_board.jpg)

### Mediante una simulación

Es posible probar el funcionamiento del sistema sin tener el hardware físico para el cual fue diseñado gracias al banco de pruebas que se proporciona con el proyecto. Esto no es mas que una simulación de diferentes entradas que se le podrían dar al hardware real, permitiendo observar cómo este se comportaría.

Para ejecutar el banco de pruebas, hará falta modificar lévemente el proyecto para que compile dicha simulación y, se necesitará un programa adicional llamado ModelSim-Altera.

> 📝**Nota:** El programa de simulación ModelSim-Altera solo se encuentra disponible en versiones más antiguas del softare [Quartus II][1], concretamente, la versión que se recomienda en este proyecto (la 18.1) trae consigo la posibilida de instalar dicho programa de simulación en el setup inicial.

> ❗**Importante:** Es necesario configurar [Quartus II][1] para que pueda ejecutar correctamente el programa de simulación, la guía oficial se encuentra en el siguiente [enlace](https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-examples/quartus/simulation-nativelink-howto.html).

La única modificación que se ha de realizar es la de tomar como base, el sistema que no tiene divisores de reloj incorporados, esto es simplemente porque los tiempos en simulación se harían muy largos y la prueba no está pensada para que existan este tipo de retardos adicionales. Para realizar esto simplemente se ha de acceder a la configuración del proyecto mediante la opción del menú `Assignments > Settings...` y en la pestaña de `General` cambiar el campo `Top-level entity` de `SISTEMA` a `sistema_sin_clk_div`.

Tras hacer esto se debe recompilar el proyecto usando `Ctrl + L` o mediante el botón de la interfaz.

Una vez el programa se haya terminado de compilar, se puede ejecutar la simulación desde la opción del menú `Tools > Run Simulation Tool > RTL Simulation`. Esto hará que se abra el programa de simulación y se ejecute este con unos valores predefinidos, mostrándonos una gráfica en el tiempo con el estado de todas las señales del sistema.

## 📜 Licencia

Este proyecto se adhiere a los principios de la [Licencia MIT](https://choosealicense.com/licenses/mit/#), garantizando la libertad para usar, modificar y distribuir el software con mínimas restricciones.

## 🔧 Posibles mejoras

- **Simplificar el diseño:** actualmente, la implementación se basa en definir diferentes componenetes de VHDL de manera aislada y, posteriormente, instanciarlos todos en un solo componenete principal que se encarga de controlar al resto. Este proceso se podría simplificar, moviendo gran parte de los componentes y sus funciones a una librería externa y rompiendo el sistema en piezas más simples.
- **Reducir el número de condicionales y variables boleanas:** la implementación actual emplea una gran cantidad de variables boleanas a modo de flags para comunicar ciertos estados entre los diferentes componenetes y procesos, abusando en cierta manera de muchos condicionales debido a ello.

[1]: https://www.intel.com/content/www/us/en/software-kit/665990/intel-quartus-prime-lite-edition-design-software-version-18-1-for-windows.html (Quartus II Download)
[2]: https://www.terasic.com.tw/cgi-bin/page/archive.pl?No=593 (Terasic DE0-Nano)
