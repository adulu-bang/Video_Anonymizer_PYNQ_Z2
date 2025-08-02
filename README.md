# Real-Time Video Anonymizer on FPGA (PYNQ-Z2)

## Project Overview

This project implements a **real-time video anonymization** pipeline on the **PYNQ-Z2 FPGA board**. It captures live webcam input, stores the pixels in every frame in the DDR memory. From the DDR memory, through AXI memory mapped, it is sent to the DMA engine, which further converts it to AXI Stream and sends it to out custom Verilog IP for processing. After processing, the pixels are streamed to the DMA again, which again sends it to the DDR memory through AXI memory-mapped engine. This processed image frame is restructured to give the anonymized video.

---

## Technologies Used

| Component         | Tool / Framework             |
|------------------|------------------------------|
| Board            | PYNQ-Z2                      |
| Language         | Verilog (custom IP), Python  |
| Frameworks       | AXI, DMA        |
| Communication    | AXI4-Lite, AXI-DMA, AXI-Stream          |
| Image Processing | On Verilog using normalized RGB Values |
| Tools            | Vivado, PYNQ Framework       |

---
