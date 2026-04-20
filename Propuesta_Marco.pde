// ======================================================================
// MODELO DE PROPAGACIÓN DE RUMORES - AUTÓMATA CELULAR
// Simulación similar al del esparcimiento de una enfermedad (paciente cero, propagación/infectados y recuperados)
// ======================================================================

// --- 1. VARIABLES GLOBALES DEL ESCENARIO ---
int columnas, filas;
int resolucion = 25; // Tamaño en píxeles de cada celda ("personita").

// Matriz principal que guarda el estado actual de cada persona.
// Estados posibles: 
// 0: Ignorante (no conoce el rumor)
// 1: Chismoso (conoce el rumor y lo propaga)
// 2: No chismoso (conoce el rumor pero decide no propagarlo/contagiar)
int[][] poblacion;

// --- 2. VARIABLES DEL MODELO MATEMÁTICO ---
float B = 0.5; // Probabilidad base fija de que un ignorante se vuelva chismoso al escuchar el rumor.
boolean simulando = false; // Variable de control para pausar (false) o reproducir (true) la simulación.

// --- 3. PALETA DE COLORES VISUALES ---
color colorIgnorante = color(46, 204, 113);     // Verde: Susceptible a infectarse.
color colorChismoso = color(231, 76, 60);       // Rojo: Foco de infección, propagando activamente.
color colorNoChismoso = color(241, 196, 15);    // Amarillo: Inmune/recuperado, actúa como barrera para el rumor.

// ======================================================================
// CONFIGURACIÓN INICIAL (Se ejecuta una sola vez al iniciar)
// ======================================================================
void setup() {
  size(800, 800); // Tamaño de la ventana de simulación
  
  // Calculamos cuántas columnas y filas caben en la pantalla según la resolución
  columnas = width / resolucion;
  filas = height / resolucion;
  
  // Inicializamos la matriz con las dimensiones calculadas
  poblacion = new int[columnas][filas];
  
  // Llamamos a la función que pone a todos en estado 0 (Verde/Ignorante)
  reiniciarPoblacion(); 
}

// ======================================================================
// CICLO DE DIBUJO (Se ejecuta continuamente, 60 veces por segundo por defecto)
// ======================================================================
void draw() {
  background(30, 35, 40); // Limpiamos la pantalla con un fondo gris oscuro en cada frame
  
  // 1. DIBUJAR LA POBLACIÓN ACTUAL
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
  
  // 2. ACTUALIZAR EL MODELO (SI ESTÁ CORRIENDO)
  // frameCount % 5 == 0 hace que la simulación vaya un poco más lento (1 actualización cada 5 frames)
  // para que se pueda apreciar cómo avanza el rumor, en lugar de que ocurra instantáneamente.
  if (simulando && frameCount % 5 == 0) {
    aplicarReglasDelRumor(); 
  }
  
  // 3. DIBUJAR LA INTERFAZ DE USUARIO (Textos informativos)
  fill(255);
  textSize(16);
  text("Estado: " + (simulando ? "Corriendo..." : "PAUSADO (ESPACIO para iniciar, 'R' para resetear)"), 15, 25);
}

// ======================================================================
// INTERACCIÓN CON EL TECLADO Y MOUSE
// ======================================================================

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

// ======================================================================
// REGLAS DEL AC
// ======================================================================
void aplicarReglasDelRumor() {
  // CRÍTICO: Creamos una nueva matriz temporal.
  int[][] nuevaPoblacion = new int[columnas][filas];
  
  // Recorremos cada celda del escenario
  for (int i = 0; i < columnas; i++) {
    for (int j = 0; j < filas; j++) {
      
      int estadoActual = poblacion[i][j];
      int vecinosChismosos = contarVecinosChismosos(i, j); // Obtenemos cuántos vecinos en rojo tiene
      
      // --- REGLA 1: SI ES IGNORANTE (0) ---
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
      
      // --- REGLA 2: SI ES CHISMOSO (1) ---
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
      
      // --- REGLA 3: SI ES NO CHISMOSO (2) ---
      else if (estadoActual == 2) { 
        // Es un estado absorbente (probabilidad 1 de quedarse igual).
        // Una vez que es amarillo, jamás vuelve a ser verde o rojo.
        nuevaPoblacion[i][j] = 2; 
      }
    }
  }
  
  // Finalmente, reemplazamos la matriz antigua con la nueva matriz calculada
  poblacion = nuevaPoblacion;
}

boolean barrier(int col, int row) {
  return col >= 0 && col < columnas && row >= 0 && row < filas;
}

// ======================================================================
// VECINDAD DE MOORE CON FRONTERA FIJA (sin toroide)
// ======================================================================
int contarVecinosChismosos(int x, int y) {
  int count = 0;

  // Recorremos los 9 cuadrantes alrededor de la celda (x,y), incluyendo ella misma
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {

      // Omitimos la celda central (0,0) porque no se puede ser vecino de uno mismo
      if (i == 0 && j == 0) continue;

      int col = x + i;
      int row = y + j;

      // BARRERA: si el vecino cae fuera del grid, simplemente lo ignoramos
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

// ======================================================================
// FUNCIÓN PARA DIBUJAR HUMANITOS
// ======================================================================
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

 //FIN :b
