// Modelo de propagación de rumores usando autómatas celulares
// Simulación similar al del esparcimiento de una enfermedad (paciente cero, propagación/infectados y recuperados)

// Variables globales del escenario
int columnas, filas;
int resolucion = 25; // Tamaño en píxeles de cada celda ("personita").

// Matriz principal que guarda el estado actual de cada persona.
// Estados posibles: 
// 0: Ignorante (no conoce el rumor)
// 1: Chismoso (conoce el rumor y lo propaga)
// 2: No chismoso (conoce el rumor pero decide no propagarlo/contagiar)
int[][] poblacion;

// Variables del modelo matemático
float B = 0.5; // Probabilidad base fija de que un ignorante se vuelva chismoso al escuchar el rumor.
boolean simulando = false; // Variable de control para pausar (false) o reproducir (true) la simulación.

// Paleta de colores visuales
color colorIgnorante = color(46, 204, 113);     // Verde: Susceptible a infectarse (ignorante)
color colorChismoso = color(231, 76, 60);       // Rojo: Foco de infección, propagando activamente (chismoso)
color colorNoChismoso = color(241, 196, 15);    // Amarillo: Inmune/recuperado, actúa como barrera para el rumor (no chismoso)

// Configuración inicial (Se ejecuta una sola vez al iniciar)

int generaciones = 0;

int[] generacionesPorDecena; // guarda en qué generación se alcanzó 10, 20, 30... enterados



void setup() {
  size(800, 800); // Tamaño de la ventana de simulación
  
  // Calculamos cuántas columnas y filas caben en la pantalla según la resolución
  columnas = width / resolucion;
  filas = height / resolucion;
  
  // Inicializamos la matriz con las dimensiones calculadas
  poblacion = new int[columnas][filas];
  generacionesPorDecena = new int[11];  
  // Llamamos a la función que pone a todos en estado 0 (Verde/Ignorante)
  reiniciarPoblacion(); 
}

// Ciclo de dibujo (Se ejecuta continuamente, 60 veces por segundo por defecto)

void draw() {
  background(30, 35, 40); // Limpiamos la pantalla con un fondo gris oscuro en cada frame
  
  // Dibujar la población actual
  // Recorremos toda la matriz para dibujar a cada "personita" según su estado
  for (int i = 0; i < columnas; i++) {
    for (int j = 0; j < filas; j++) {
      int x = i * resolucion; // Convertimos índice de matriz a píxeles en X
      int y = j * resolucion; // Convertimos índice de matriz a píxeles en Y
      
      color colorActual = color(0);
      
      // Asignamos el color correspondiente al valor numérico de la matriz
      if (poblacion[i][j] == 0) colorActual = colorIgnorante;
      else if (poblacion[i][j] == 1) colorActual = colorChismoso;
      else if (poblacion[i][j] == 2) colorActual = colorNoChismoso;
      
      // Dibujamos el icono humano
      dibujarPersona(x, y, resolucion, colorActual);
    }
  }
  
  // Actualizar el modelo (si está corriendo)
  // frameCount % 5 == 0 hace que la simulación vaya un poco más lento (1 actualización cada 5 frames)
  // para que se pueda apreciar cómo avanza el rumor, en lugar de que ocurra instantáneamente.
  if (simulando && frameCount % 5 == 0) {
    aplicarReglasDelRumor(); 
  }
  int totalIgnorantes = contarEstado(0);
  int totalChismosos = contarEstado(1);
  int totalNoChismosos = contarEstado(2);
  int totalEnterados = totalChismosos + totalNoChismosos;

  float porcentajeIgnorantes = calcularPorcentaje(totalIgnorantes);
  float porcentajeChismosos = calcularPorcentaje(totalChismosos);
  float porcentajeNoChismosos = calcularPorcentaje(totalNoChismosos);
  float porcentajeEnterados = calcularPorcentaje(totalEnterados);

  registrarDecenasEnterados(porcentajeEnterados);
  int ultimaDecenaAlcanzada = obtenerUltimaDecenaAlcanzada(porcentajeEnterados);
  
  // Dibujar interfaz de usuario (Textos informativos)
  fill(255);
  textSize(16);

  fill(0, 160);
rect(10, 5, 430, 185);
fill(255);
  text("Generaciones: " + generaciones, 15, 25);
  text("Ignorantes: " + totalIgnorantes + " (" + nf(porcentajeIgnorantes, 0, 2) + "%)", 15, 50);
  text("Chismosos: " + totalChismosos + " (" + nf(porcentajeChismosos, 0, 2) + "%)", 15, 75);
  text("No chismosos: " + totalNoChismosos + " (" + nf(porcentajeNoChismosos, 0, 2) + "%)", 15, 100);
  text("Enterados: " + totalEnterados + " (" + nf(porcentajeEnterados, 0, 2) + "%)", 15, 125);

  if (ultimaDecenaAlcanzada >= 10) {
    text("Generaciones para llegar a " + ultimaDecenaAlcanzada + "% enterados: " 
     + generacionesPorDecena[ultimaDecenaAlcanzada / 10], 15, 150);
  } else {
    text("Generaciones para llegar a X0% enterados: aun no se alcanza 10%", 15, 150);  }

text("Estado: " + (simulando ? "Corriendo..." : "PAUSADO (ESPACIO para iniciar, 'R' para resetear)"), 15, 175);
}

// Interacción con el teclado y mouse

// Función que detecta cuando se presiona una tecla
void keyPressed() {
  if (key == ' ') {
    simulando = !simulando; // Invertimos el estado: si estaba pausado arranca, y viceversa.
  }
  if (key == 'r' || key == 'R') {
    reiniciarPoblacion(); // Resetea el escenario a una población "sana" (sin infectados de chisme ;v)
  }
}

// Devuelve a toda la matriz al estado inicial (0) y pausa la simulación
void reiniciarPoblacion() {
  simulando = false;
  generaciones = 0;

  for (int k = 0; k < generacionesPorDecena.length; k++) {
    generacionesPorDecena[k] = -1;
  }

  for (int i = 0; i < columnas; i++) {
    for (int j = 0; j < filas; j++) {
      poblacion[i][j] = 0;
    }
  }
}

// Permite "pintar" chismosos (estado 1) arrastrando el clic del ratón
void mouseDragged() { iniciarRumor(); }
// Permite crear un chismoso con un solo clic
void mousePressed() { iniciarRumor(); }

// Traduce la posición del ratón en píxeles a una coordenada (i, j) en la matriz
void iniciarRumor() {
  int i = floor(mouseX / resolucion);
  int j = floor(mouseY / resolucion);
  
  // Verificamos que el ratón esté dentro de los límites de la pantalla para evitar errores
  if (i >= 0 && i < columnas && j >= 0 && j < filas) {
    poblacion[i][j] = 1; // Plantamos al "paciente cero" del rumor
  }
}

// Reglas del Autómata Celular

void aplicarReglasDelRumor() {
  // Creamos una nueva matriz temporal (importante)
  int[][] nuevaPoblacion = new int[columnas][filas];
  
  // Recorremos cada celda del escenario
  for (int i = 0; i < columnas; i++) {
    for (int j = 0; j < filas; j++) {
      
      int estadoActual = poblacion[i][j];
      int vecinosChismosos = contarVecinosChismosos(i, j); // Obtenemos cuántos vecinos en rojo tiene
      
      // Regla 1: si es ignorante (0) 

      if (estadoActual == 0) { 
        
        // k es la proporción de vecinos infectados (sobre el máximo posible en Vecindad de Moore: 8)
        float k = vecinosChismosos / 8.0; 
        
        // Fórmula de propagación: P = 1 - (1-B)^K
        float probVolverseChismoso = 1.0 - pow(1.0 - B, k); 
        
        // Usamos random(1) para generar un número aleatorio entre 0 y 1.
        // Si el número es menor a la probabilidad calculada, se efectúa el cambio de estado.
        if (random(1) < probVolverseChismoso) {
          nuevaPoblacion[i][j] = 1; // Se infecta un nuevo chismoso
          
        } else {
          // Si no se volvió chismoso, evaluamos si de casualidad pasa a ser "No chismoso" directo
          // Esto requiere que al menos haya escuchado el rumor (vecinosChismosos > 0)
          // Le damos una muy baja probabilidad (5% o 0.05) para este salto directo al estado amarillo.
          if (vecinosChismosos > 0 && random(1) < 0.05) {
             nuevaPoblacion[i][j] = 2; // Lo escucha, pero decide no contarlo
          } else {
             nuevaPoblacion[i][j] = 0; // Permanece en estado ignorante
          }
        }
      } 
      
      // Regla 2: Si es chismoso (1)
      else if (estadoActual == 1) { 
        // Si tiene demasiados vecinos chismosos, el rumor pierde novedad.
        // Probabilidad de volverse no chismoso = (vecinos chismosos / 8)
        float probVolverseNoChismoso = vecinosChismosos / 8.0; 
        
        if (random(1) < probVolverseNoChismoso) {
          nuevaPoblacion[i][j] = 2; // El rumor ya es viejo, deja de propagarlo
        } else {
          nuevaPoblacion[i][j] = 1; // Continúa activo esparciendo el rumor
        }
      } 
      
      // Regla 3: Si es no chismoso (2)
      else if (estadoActual == 2) { 
        // Es un estado absorbente (probabilidad 1 de quedarse igual).
        // Una vez que es amarillo, jamás vuelve a ser verde o rojo.
        nuevaPoblacion[i][j] = 2; 
      }
    }
  }
  
  // Finalmente, reemplazamos la matriz antigua con la nueva matriz calculada
  poblacion = nuevaPoblacion;
  generaciones++;
}

boolean barrier(int col, int row) {
  return col >= 0 && col < columnas && row >= 0 && row < filas;
}

// Vecindad de Moore con frontera fija (se ignora lo que esté fuera del espacio celular)

int contarVecinosChismosos(int x, int y) {
  int count = 0;

  // Recorremos los 9 cuadrantes alrededor de la celda (x,y), incluyendo ella misma
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {

      // Omitimos la celda central (0,0) porque no se puede ser vecino de uno mismo
      if (i == 0 && j == 0) continue;

      int col = x + i;
      int row = y + j;

      // Barrera: si el vecino cae fuera del grid, simplemente lo ignoramos
      if (!barrier(col, row)) {
        continue;
      }

      // Si el vecino es un Chismoso (1), lo sumamos al contador
      if (poblacion[col][row] == 1) {
        count++;
      }
    }
  }
  return count; // Retornamos el total de chismosos alrededor (entre 0 y 8)
}

// Función para dibujar "personitas"

void dibujarPersona(float x, float y, float tamano, color c) {
  fill(c);      // Color de relleno
  noStroke();   // Sin bordes para un diseño más limpio
  
  // Calculamos las proporciones del cuerpo en base a la resolución elegida
  float tamanoCabeza = tamano * 0.4;
  float anchoCuerpo = tamano * 0.7;
  float altoCuerpo = tamano * 0.5;
  
  // Obtenemos el punto central de la celda actual para alinear la figura
  float centroX = x + tamano / 2;
  float centroY = y + tamano / 2;
  
  // Dibujamos la cabeza (Círculo en la parte superior)
  ellipse(centroX, centroY - tamano*0.15, tamanoCabeza, tamanoCabeza);
  
  // Dibujamos los hombros/cuerpo (Un arco en la parte inferior apuntando hacia arriba)
  arc(centroX, centroY + tamano*0.3, anchoCuerpo, altoCuerpo, PI, TWO_PI);
}

int contarEstado(int estadoBuscado) {
  int total = 0;

  for (int i = 0; i < columnas; i++) {
    for (int j = 0; j < filas; j++) {
      if (poblacion[i][j] == estadoBuscado) {
        total++;
      }
    }
  }

  return total;
}

float calcularPorcentaje(int cantidad) {
  int totalCeldas = columnas * filas;

  if (totalCeldas == 0) {
    return 0;
  }

  return (float)cantidad * 100.0 / totalCeldas;
}

void registrarDecenasEnterados(float porcentajeEnterados) {
  for (int decena = 10; decena <= floor(porcentajeEnterados); decena += 10) {
    int indice = decena / 10;

    if (indice < generacionesPorDecena.length && generacionesPorDecena[indice] == -1) {
      generacionesPorDecena[indice] = generaciones;
    }
  }
}

int obtenerUltimaDecenaAlcanzada(float porcentajeEnterados) {
  return (floor(porcentajeEnterados) / 10) * 10;
}

