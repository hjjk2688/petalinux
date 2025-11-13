#  Zybo Z7-20 AXI-ALU with PetaLinux (Bare-metal Memory Access)

이 프로젝트는 **Zybo Z7-20 (Zynq-7020)** 보드에서 Vivado로 생성한 **AXI-Lite 기반 ALU IP**를  
**PetaLinux 사용자 공간(/dev/mem)** 에서 직접 접근하여 테스트하는 예제입니다.  
커널 드라이버 없이, 메모리 매핑 방식으로 AXI 레지스터를 제어합니다.

---

## 📁 프로젝트 구조

```
zybo_alu_project/
├── vivado_ip/
│   ├── alu_v1_0.v
│   ├── alu_v1_0_S00_AXI.v      # 수정된 AXI 슬레이브 파일 (ALU 연결 포함)
│   └── alu.v                   # 간단한 산술연산 모듈
├── petalinux_app/
│   ├── alu_test.c              # /dev/mem 접근용 C 테스트 프로그램
└── README.md                   # (현재 문서)
```

---

##  1. Vivado Design 개요

### 🔹 Block Diagram 구성
- **Zynq Processing System (PS7)**  
  - M_AXI_GP0 인터페이스 활성화  
- **ALU IP (axi_alu_v1_0)**  
  - S_AXI 포트 → PS7 M_AXI_GP0 연결  
  - 인터럽트 불필요  
- **Address Editor**  
  - ALU IP Base Address: `0x43C0_0000`
  - Range: 64 KB
<img width="1355" height="565" alt="image" src="https://github.com/user-attachments/assets/5ae11f9b-8abe-4bab-b3d0-ffa6c564569f" />



### 🔹 AXI Slave 수정 포인트
`alu_v1_0_S00_AXI.v`의 주요 변경:
- `ALU.result` → 중간 `wire`(`alu_result`)로 연결
- `slv_reg1`은 **읽기 전용**으로 지정, `ena=1` 시 결과 래치
- 읽기 MUX는 블로킹(`=`) 할당 사용

---

##  2. Vivado → Bitstream → PetaLinux Flow

1. Vivado에서 Block Design → HDL Wrapper 생성  
2. Bitstream 생성 (`Generate Bitstream`)  
3. `File → Export → Export Hardware (Include Bitstream)`  
4. PetaLinux 프로젝트 생성 및 하드웨어 가져오기:
    ```bash
    cp /mnt/share/design_top_wrapper.xsa ~/projects/
    
    # PetaLinux 환경이 활성화되어 있는지 확인
    unzip -l design_top_wrapper.xsa
    
    # Unzip
    unzip design_top_wrapper.xsa -d design_top_wrapper
    
    # bit 파일 복사
    cp design_top_wrapper/design_top_wrapper.bit myprojec/image/linux
    
    cd ~/projects
    
    # PetaLinux 환경이 활성화되어 있는지 확인
    source ~/petalinux/2022.2/settings.sh
    
    # 프로젝트 디렉토리로 이동
    cd myproject
    
    # XSA 파일로 하드웨어 설정
    petalinux-config --get-hw-description=~/projects/

    petalinux-config -c rootfs
    ```
   
5. 빌드 및 부팅 이미지 생성:
    ```bash
    petalinux-build -c fsbl-firmware -x cleansstate # 에러 발생시
    petalinux-build -c device-tree -x cleansstate  # 에러 발생시
    petalinux-build
    
    # 부트 이미지 생성 (BOOT.BIN)
    petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_1_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force
    
    # WIC 이미지 생성
    petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/
    ```

---

##  3. 레지스터 맵 & ALU opcode
### 레지스터 맵
| 주소(Offset) | 이름 | 설명 | 접근 |
|---------------|-------|------|-------|
| 0x00 | **REG0** | `{a[31:24], b[23:16], …, ena[3], opcode[2:0]}` | RW |
| 0x04 | **REG1** | `{16'h0, result[15:0]}` (ALU 결과) | **RO** |
| 0x08 | **REG2** | Reserved | RW | 
| 0x0C | **REG3** | Reserved | RW |

> ⚠️ REG1은 AXI 쓰기 금지. ALU enable(ena=1)일 때만 결과가 래치됩니다.
> "래치(latch)된다"는 것은 특정 조건이 만족되었을 때의 결과값을 '찰칵'하고 사진 찍듯이 붙잡아서 저장하고, 그 값을 계속 유지하는 것

### ALU opcode

| opcode | 연산 | 설명 |
|--------:|------|------|
| 0 | ADD | a + b |
| 1 | SUB | a - b |
| 2 | MUL | a × b |
| 3 | DIV | a ÷ b |
| 4 | AND | a & b |
| 5 | OR  | a \| b |
| 6 | XOR | a ^ b |
| 7 | NOT | ~a |

---

##  4. PetaLinux 테스트 코드

`alu_test.c` — `/dev/mem` 접근 예제

```bash
# 컴파일 (PC 에서)
arm-linux-gnueabihf-gcc -o alu_test alu_test.c

# 컴파일 (보드 안에서)
gcc -O2 -Wall -o alu_test alu_test.c
```

## 5. ALU IP Code
```Verilog
	// slave = wready,awready / master = WVALID , AWVALID
	// 네개가 다 활성화 돼야 write 가능
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;   

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1: begin
                // slave(alu) reg 2번은 result 값을 저장하는곳 / result 된 결과를 read 하는곳이니까  write는 막아둔다.
              end

	          2'h2: begin
	             for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	               if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            	 Respective byte enables are asserted as per write strobes 
	                 Slave register 2
	                 slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	               end
             
              end

	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                 Respective byte enables are asserted as per write strobes 
	                 Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                    //   slv_reg0 <= slv_reg0;
	                    //   slv_reg1 <= slv_reg1;
	                    //   slv_reg2 <= slv_reg2;
	                    //   slv_reg3 <= slv_reg3; 
                        //안함 왜 안함 ?  no-op
	                    end
	        endcase
            if (slv_reg0[3]) begin  // slv_reg0 이 input값이 저장된곳이고 거기야 slv_reg[3]이 input enable 값임 alu module 코드짤때 enable 1일떄 실행되게해서 check
                 slv_reg1 <= {16'h0000, alu_result}; //처음 인풋줄떄 확인하고 결과에 값적어놓음 
            end

	      end
	  end
	end    
```
- slv_reg0 : input 들어오는곳으로 수정 X
- slv_reg1 : alu 계산된 결과 result 가 read 되는곳으로 write가 되는걸 방지 코드수정
- enable == 1 이면 slv_reg1 에 result 값 update

---

## 6. 스위치 / LED 추가

*   REG2 (0x08): 스위치 상태 읽기 (읽기 전용) → REG2[3:0] = {SW3..SW0}
*   REG3 (0x0C): LED 제어 (쓰기/읽기 가능) → LED[3:0] = REG3[3:0]

1.  RTL 수정 (alu_v1_0_S00_AXI.v)
    -   1-1. 포트 추가
        *   IP의 S00_AXI 모듈 포트에 스위치 입력/LED 출력 포트를 추가

        ```verilog
        // Users to add ports here
        input  wire [3:0] sw_in,   // ★ 추가: 보드의 4개 스위치 입력
        output wire [3:0] led_out  // ★ 추가: 보드의 4개 LED 출력
        // User ports ends
        ```

    -   1-2. 입력 동기화(권장) + 디바운스(선택)
        *   스위치는 비동기이므로 2FF 동기화 정도는 해두는 게 안전합니다.

        ```verilog
            //  동기화 플립플롭  => metastability(클럭이 안맞을떄 발생할수있는문제) 해결   sw_ff1으로 한번 막고 sw_ff2로 안정적이게 신호줌
            reg [3:0] sw_ff1, sw_ff2;
            always @(posedge S_AXI_ACLK) begin
                if (!S_AXI_ARESETN) begin
                    sw_ff1 <= 4'b0;
                    sw_ff2 <= 4'b0;
                end else begin
                    sw_ff1 <= sw_in; // 외부에서 input으로 들어오는 스위치 값
                    sw_ff2 <= sw_ff1;
                end // 'Fend' -> 'end' 로 수정했습니다.
            end
             // REG2에 반영할 스위치
            assign sw_sync = sw_ff2;
            assign led_out = slv_reg3[3:0]; // reg3 4bit led구동
        // User logic ends
        ```

    -   1-3. REG2/REG3 매핑
        *   REG2: 읽기 전용으로 스위치 상태를 반영
        *   REG3: 쓰기한 값의 하위 4비트로 LED를 구동

        *   (A) 쓰기 로직(기존 slv_reg_wren case문) 유지 + REG3 쓰기 허용
            ```verilog
            // case (axi_awaddr[...]):
            2'h2: begin
            //REG2 (0x08): 스위치 상태 읽기 (읽기 전용) → REG2[3:0] = {SW3..SW0} => 따라서 reg1 처럼 read용이라서 비활성화

            //REG3 (0x0C): LED 제어 (쓰기/읽기 가능) → LED[3:0] = REG3[3:0]
            end
            2'h3: begin
              for (byte_index=0; byte_index<=(C_S_AXI_DATA_WIDTH/8)-1; byte_index=byte_index+1)
                if (S_AXI_WSTRB[byte_index])
                  slv_reg3[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
            end
            ```

        *   (B) 읽기 MUX에 REG2, REG3 반영
            ```verilog
            always @(*) // 'always @AppData\Local...' -> 'always @(*)' 로 수정했습니다.
            begin
              case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                2'h0: reg_data_out = slv_reg0;
                2'h1: reg_data_out = slv_reg1;                         // ALU 결과
                2'h2: reg_data_out = {28'b0, sw_sync};                 // REG2: SW 입력
                2'h3: reg_data_out = slv_reg3;                         // REG3: LED 레지스터
                default: reg_data_out = {C_S_AXI_DATA_WIDTH{1'b0}};
              endcase
            end
            ```

        *   (C) LED 출력 연결
            ```verilog
            assign led_out = slv_reg3[3:0]; //  REG3 하위 4비트로 LED 구동
            ```

        *   참고: REG2를 완전 읽기 전용으로 두려면, 쓰기 case에서 2'h2는 아무 것도 하지 않도록 두는게 좋음

2.  ALU IP 상위(alu_v1_0.v) 포트 전달
    *   IP 패키지의 top 모듈(alu_v1_0.v)
    ```verilog
    module alu_v1_0 #(
      // params...
    )(
      // AXI 포트들 ...
      input  wire [3:0] sw_in,     // sw 입력
      output wire [3:0] led_out    // led 출력
    );
      // ...

      alu_v1_0_S00_AXI # (
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
      ) alu_v1_0_S00_AXI_inst (
        // 기존 AXI 연결 ...
    //user AXI
    .sw_in(sw_in), //switch
    .led_out (led_out) //led
      );

    endmodule
    ```

3.  Vivado Block Design 연결
    *   ALU IP Re-package 후 BD에 다시 추가/갱신
    *   ALU IP의 sw_in[3:0], led_out[3:0] 포트를 Make External로 빼거나, 별도 top wrapper에서 외부 핀과 연결
    *   XDC 제약에 Zybo Z7-20 보드의 SW0..SW3, LD0..LD3 핀을 매핑
    *   핀번호는 Digilent 제공 Zybo Z7-20 Master XDC에서 복사(보드 리비전/모델별 다를 수 있으니 반드시 그 파일 참고)
    *   각 핀에 IOSTANDARD LVCMOS33 설정

    ```tcl
    ##Switches
    set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L19N_T3_VREF_35 Sch=sw[0]
    set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L24P_T3_34 Sch=sw[1]
    set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L4N_T0_34 Sch=sw[2]
    set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]


    ##LEDs
    set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L23P_T3_35 Sch=led[0]
    set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L23N_T3_35 Sch=led[1]
    set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_0_35 Sch=led[2]
    set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]
    ```
======
## 7. 실행결과
#### 1. ALU
```
input 
	- a = 0x32
	- b = 0x0A
	- enable = 1
	- opcode = 011
	=> eable + opcode : 하위 4bit

root@myproject:~# devmem 0x43C00000 32 0x320A000A // reg0 
root@myproject:~# devmem 0x43C00004 //reg1 접근 

# 예상 출력 결과
0x000001F4 // 10진수 0x32 = 50 / 0x0A = 10  => MUX = 0x1FA = 500
```
실행결과

<img width="503" height="53" alt="image" src="https://github.com/user-attachments/assets/ee548ba8-cdc9-4518-8b28-263956ec7609" />

### 2.Switch Read
* 스위치 상태를 단순히 읽어 들임


