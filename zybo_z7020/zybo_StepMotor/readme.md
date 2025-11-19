# Zybo_StepMotor

## Standalone Step Motor Controller : StepMotor(28BYJ-48) 5V - ULN2003

### ⚙️ 1.회로

<img width="357" height="241" alt="002" src="https://github.com/user-attachments/assets/e3528fc4-6645-4929-b022-2307864cf76e" />
<br>
<img width="608" height="186" alt="003" src="https://github.com/user-attachments/assets/e3575f39-af0e-401a-8ddc-dfcf0dacb800" />
<br>

---
https://cookierobotics.com/042/

<img width="284" height="185" alt="001" src="https://github.com/user-attachments/assets/a0466c38-e394-4f88-85ea-c284e5b2f055" />
<img width="384" height="185" alt="002" src="https://github.com/user-attachments/assets/1b102543-878c-488b-a975-708d9e810989" />
<br>
<img width="296" height="134" alt="003" src="https://github.com/user-attachments/assets/c6bcccd2-034f-4bcf-b247-cc0b3bcb0c4e" />
<img width="292" height="201" alt="004" src="https://github.com/user-attachments/assets/471f5e82-0914-4f7d-a2f8-f7d2527c72af" />
<br>

---

## zyboz720 board 와 AXI_GPIO 를 이용한 StepMotor 제어

- zyboz7020 board : https://blog.naver.com/hjjk2688/224070789056  
- AXI_GPIO : https://blog.naver.com/hjjk2688/224071906732

---

## AXI4 Peripheral IP(StepMotor 생성

### Block Diagram

<img width="1314" height="498" alt="image" src="https://github.com/user-attachments/assets/2d80fcca-6016-4b2c-b813-1fbfa3c6dc03" />

### 1. Create and Package New IP 시작
Vivado에서:
```
Tools → Create and Package New IP...
→ Create a new AXI4 peripheral 선택
→ Next
```

### 2. Peripheral Details 설정
```
Name: stepper_motor_ctrl (또는 원하는 이름)
Version: 1.0
Display name: Stepper Motor Controller
Description: ULN2003 Stepper Motor Controller with AXI4-Lite interface
```

### 3. Add Interfaces
```
Interface Type: AXI4-Lite
Interface Mode: Slave
Data Width: 32
Number of Registers: 4 (최소한 필요)
```

추천 레지스터 맵:
* Offset 0x00: Control Register (run, dir, half_full, enable)
* Offset 0x04: Status Register (현재 step_idx, coils 상태)
* Offset 0x08: Speed Register (STEPS_PER_SEC 설정)
* Offset 0x0C: Reserved

<img width="842" height="572" alt="004" src="https://github.com/user-attachments/assets/dcbb97ff-0f82-4658-9496-09764785ba2b" />
<br>
<img width="842" height="572" alt="005" src="https://github.com/user-attachments/assets/109a677f-2991-4562-8b52-2a7c1dc8ddc5" />
<br>
<img width="842" height="572" alt="007" src="https://github.com/user-attachments/assets/ac712f1d-8ef3-4dc8-91ab-1f5f9815998a" />
<br>
<img width="842" height="572" alt="008" src="https://github.com/user-attachments/assets/49a313c0-b29a-4c6c-970a-2b527c70bf0c" />
<br>
<img width="842" height="572" alt="009" src="https://github.com/user-attachments/assets/58fcd524-f69e-4c13-9eea-f4b4aa9f1cb0" />
<br>
<img width="842" height="572" alt="010" src="https://github.com/user-attachments/assets/28b3842d-7169-49b3-9bd4-801bb6897fca" />
<br>
<img width="842" height="572" alt="011" src="https://github.com/user-attachments/assets/2108e12f-9342-4be1-915f-b82da6645ba0" />
<br>
<img width="1080" height="657" alt="012" src="https://github.com/user-attachments/assets/301d7c4f-fac9-4cb0-b415-a6fdcb65766b" />
<br>
<img width="1077" height="655" alt="013" src="https://github.com/user-attachments/assets/63413475-cbfc-4413-bda9-00fe96b3642c" />
<br>
