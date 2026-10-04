
import numpy as np
import matplotlib.pyplot as plt

# ==============================================================================
# FASE 1: SIMULACIÓN DE ENTRADA DEL SENSOR (TU CÓDIGO ORIGINAL)
# ==============================================================================

# 1. Definir el vector de tiempo (100 puntos entre 0 y 1 segundo)
N_PUNTOS = 100
tiempo = np.linspace(0, 1, N_PUNTOS)

# 2. Señal pura del sensor: Una onda senoidal lenta (2 Hz)
# Representa el fenómeno real que queremos medir (ej: respiración, pulsaciones)
frecuencia = 2
senal_limpia = np.sin(2 * np.pi * frecuencia * tiempo)

# 3. Ruido: Perturbaciones aleatorias de alta frecuencia
np.random.seed(42)  # Para que a ti y a mí nos salgan los mismos números exactos
ruido = 0.4 * np.random.normal(size=N_PUNTOS)

# 4. Señal contaminada (lo que realmente lee el hardware)
senal_con_ruido = senal_limpia + ruido


# ==============================================================================
# FASE 2: FILTRO DE COEFICIENTES (PUNTO FLOTANTE)
# ==============================================================================
# Asignamos los pesos con forma Gaussiana/campana para suavizar la onda senoidal
# La suma de los pesos en float es exactamente 1.0 (ganancia unitaria)
w_float = np.array([0.125, 0.375, 0.375, 0.125])


# ==============================================================================
# FASE 3: CUANTIZACIÓN A INT4 (Rango con signo: -8 a +7)
# ==============================================================================

# 1. Cuantización de los Pesos Sinápticos (Filtro):
# Multiplicamos por 8 (2^3) para que la suma sea 8 y los pesos sean enteros: [1, 3, 3, 1]
w_int4 = np.round(w_float * 8).astype(int)
w_int4 = np.clip(w_int4, -8, 7) # Asegurar rango INT4

# 2. Cuantización de la Señal con Ruido:
# Escalamos la señal continua al rango [-7, +7] para aprovechar el rango INT4 sin saturar
max_amplitud = np.max(np.abs(senal_con_ruido))
senal_escalada = (senal_con_ruido / max_amplitud) * 7.0
x_int4 = np.round(senal_escalada).astype(int)
x_int4 = np.clip(x_int4, -8, 7) # Asegurar formato INT4 con signo (-8 a +7)


# ==============================================================================
# FASE 4: SIMULACIÓN DE LA NEURONA / FIR EN PYTHON
# ==============================================================================
# Simulamos exactamente lo que hará el hardware combinacional de la FPGA
y_int4 = np.zeros(N_PUNTOS, dtype=int)

for n in range(N_PUNTOS):
    if n < 3:
        y_int4[n] = 0
    else:
        # Ventana temporal de 4 muestras: [x[n], x[n-1], x[n-2], x[n-3]]
        ventana = np.array([x_int4[n], x_int4[n-1], x_int4[n-2], x_int4[n-3]])
        # Núcleo MAC: Multiplicaciones y Suma
        suma_productos = np.sum(ventana * w_int4)
        # Normalización: División entre 8 (equivalente al shift >> 3 en Verilog)
        y_int4[n] = suma_productos >> 3


# ==============================================================================
# FASE 5: EXPORTACIÓN PARA VERILOG (weights.vh)
# ==============================================================================
# Generamos el archivo de constantes que consumirá la Etapa 2 en Verilog
with open("weights.vh", "w") as f:
    f.write("// =========================================================\n")
    f.write("// Archivo generado automaticamente desde Python (Etapa 1)\n")
    f.write("// Coeficientes cuantizados a INT4 (signed 4-bit)\n")
    f.write("// Suma total = 8 (Permite normalizar con shift >>> 3)\n")
    f.write("// =========================================================\n\n")
    f.write(f"localparam signed [3:0] W0 = 4'sd{w_int4[0]};\n")
    f.write(f"localparam signed [3:0] W1 = 4'sd{w_int4[1]};\n")
    f.write(f"localparam signed [3:0] W2 = 4'sd{w_int4[2]};\n")
    f.write(f"localparam signed [3:0] W3 = 4'sd{w_int4[3]};\n")

print("-> Archivo 'weights.vh' generado con exito.")
print(f"   Pesos cuantizados INT4: W = {w_int4.tolist()}")


#==============================================================================
# FASE 6: GRAFICAR RESULTADOS DE LA ETAPA 1
# ==============================================================================
plt.figure(figsize=(10, 5))

# 1. Señal con ruido cuantizada (los picos ruidosos en escalones)
plt.plot(tiempo, x_int4, label='Entrada con Ruido (INT4)', color='orange', alpha=0.5, linestyle=':')

# 2. Señal limpia filtrada por la neurona (verás que la forma del seno se recupera)
plt.plot(tiempo, y_int4, label='Salida Filtrada Neurona (INT4)', color='blue', linewidth=2.5)

# 3. Umbrales del detector de eventos
plt.axhline(y=4, color='red', linestyle='--', alpha=0.7, label='Umbral Evento (+4)')
plt.axhline(y=-4, color='red', linestyle='--', alpha=0.7, label='Umbral Evento (-4)')

plt.title("Etapa 1: Señal Senoidal Cuantizada en INT4 y Filtrada")
plt.xlabel("Tiempo (s)")
plt.ylabel("Amplitud Discreta [-8 a +7]")
plt.legend()
plt.grid(True)
plt.show()
