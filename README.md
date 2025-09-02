# Implementation-of-backend-module-using-Verilog
This project involves designing a backend controller for a mixed-signal IC in Verilog. It manages a startup sequence: reading a serial gain configuration, enabling a ring oscillator, processing temperature sensor data through a 4-tap moving average filter, and controlling amplifier bias and core clock speed based on the filtered temperature.

- Block Diagram 
<img width="1173" height="713" alt="Screenshot 2025-09-03 044030" src="https://github.com/user-attachments/assets/499772ec-3dd3-453f-b9ab-15eea06f847a" />

<img width="984" height="684" alt="Screenshot 2025-09-03 044044" src="https://github.com/user-attachments/assets/032c0ab2-2b1a-4731-b14e-1f1389c21bed" />

- designing the backend so that it executes the following start-up sequence
<img width="1466" height="858" alt="Screenshot 2025-09-03 043926" src="https://github.com/user-attachments/assets/b1a4c871-2974-4856-adba-c0f75365c938" />

- Serial data communication
<img width="1481" height="701" alt="Screenshot 2025-09-03 044109" src="https://github.com/user-attachments/assets/5f39cf8d-3072-4775-988f-16910991b414" />

- Moving average filter
<img width="1488" height="831" alt="Screenshot 2025-09-03 044124" src="https://github.com/user-attachments/assets/ad088da9-ac9d-4ec8-a88c-e2cbc2c71768" />

- Visual verification of verilog backend design
<img width="2877" height="1471" alt="Screenshot 2025-09-03 010820" src="https://github.com/user-attachments/assets/48269782-7f37-4b32-8bbc-59a1a29a10e1" />
<img width="2849" height="1469" alt="Screenshot 2025-09-03 010753" src="https://github.com/user-attachments/assets/45c02ff5-5708-4962-8232-1e8442ac3d33" />
