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

<img width="1090" height="501" alt="image" src="https://github.com/user-attachments/assets/59a9fb54-8f17-45da-9da5-d8bacaf5d47c" />

<img width="914" height="619" alt="image" src="https://github.com/user-attachments/assets/1b7fe92f-014d-44a1-8369-a8130dd122f4" />

<img width="842" height="572" alt="009" src="https://github.com/user-attachments/assets/58fcd524-f69e-4c13-9eea-f4b4aa9f1cb0" />

<img width="842" height="572" alt="010" src="https://github.com/user-attachments/assets/28b3842d-7169-49b3-9bd4-801bb6897fca" />

<img width="842" height="572" alt="011" src="https://github.com/user-attachments/assets/2108e12f-9342-4be1-915f-b82da6645ba0" />

<img width="1083" height="599" alt="image" src="https://github.com/user-attachments/assets/86d10553-ca74-4e10-9590-80210d4937e0" />

<img width="1077" height="655" alt="013" src="https://github.com/user-attachments/assets/63413475-cbfc-4413-bda9-00fe96b3642c" />

* edit IP Block

<img width="450" height="526" alt="image" src="https://github.com/user-attachments/assets/fc7b0a70-6c91-4944-a2b4-055243d0fd6c" />


### 4. IP 구조 수정
<img width="764" height="263" alt="image" src="https://github.com/user-attachments/assets/d5e416ca-1449-4668-a5ff-a1ec42b3d48f" />


- IP를 생성시 생기는 파일 
  - stepper_motor_ctrl_v1_0.v
  - stepper_motor_ctrl_v1_0_SOO_AXI.v (<ip_name>_v1_0_S00_AXI.v)
- AXI.v 파일에 IP를 동작시키는 Module 추가 시 하위 Module로 우리가 만든 Module 이 들어감 ( ZYBO_Z720_stepper_top.v)


* stepper_motor_ctrl_v1_0.v 수정 사항항
```Verilog

timescale 1 ns / 1 ps

	module stepper_motor_ctrl_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output wire [3:0] coils,  // 우리가 사용하는 Module의 Output port 추가
		// User ports ends

    ~ 아래 내용을 같음
	stepper_motor_ctrl_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) stepper_motor_ctrl_v1_0_S00_AXI_inst

   ~ 아래 내용을 같음

		.coils_out(coils)  // Connect user port  
	);

	// Add user logic here

	// User logic ends

	endmodule

```
* stepper_motor_ctrl_v1_0_SOO_AXI.v 수정
* 아래 부분에 Module을 생성해야 아래 부분에 우리가 만듬 Stepper Motor Module 생성됨됨
 
```Verilog

 // ============================================================
    // Add user logic here
    // ============================================================
    
    // Register Map:
    // 0x00: Control Register
    //       [0] - motor_run (1=run, 0=stop)
    //       [1] - motor_dir (1=CW, 0=CCW)
    //       [2] - half_full (1=half-step, 0=full-step)
    // 0x04: Status Register (read-only)
    //       [3:0] - coils output state
    // 0x08: Speed Register (future use)
    // 0x0C: Reserved
    
    // Extract control signals directly from AXI registers
    wire motor_run    = slv_reg0[1];
    wire motor_dir    = slv_reg0[2];
    wire half_full    = slv_reg0[3];
    
    // Build input signal for stepper controller
    wire [3:0] in_signal = {half_full, motor_dir, motor_run, S_AXI_ARESETN};
    
    // Instantiate stepper motor controller
    zybo_z720_stepper_top #(
        .CLK_HZ(CLK_HZ),
        .STEPS_PER_SEC(600)
    ) stepper_inst (
        .clk(S_AXI_ACLK),
        .in_signal(in_signal),
        .coils(coils_out)
    );
    
    // Update status register with current coil states
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            slv_reg1 <= 0;
        else
            slv_reg1 <= {28'h0, coils_out};
    end

    // User logic ends

```  
#### 전체 수정 사항은 github 확인

### 5. 실행
* xdc 파일 수정 (#Pmod Header JE  제어)
```Veilrog
# xdc 에서 

##Pmod Header JE                                                                                                                  
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { coils[0] }]; #IO_L4P_T0_34 Sch=je[1]						 
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { coils[1] }]; #IO_L18N_T2_34 Sch=je[2]                     
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { coils[2] }]; #IO_25_35 Sch=je[3]                          
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { coils[3] }]; #IO_L19P_T3_35 Sch=je[4]                     
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { je[4] }]; #IO_L3N_T0_DQS_34 Sch=je[7]                  
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { je[5] }]; #IO_L9N_T1_DQS_34 Sch=je[8]                  
#set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { je[6] }]; #IO_L20P_T3_34 Sch=je[9]                     
#set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { je[7] }]; #IO_L7N_T1_34 Sch=je[10]     

```
* IP Address Map
  
<img width="612" height="301" alt="image" src="https://github.com/user-attachments/assets/2787bdd3-758f-4ffb-af44-d4e2a47f2da8" />

* Board 연결
  












