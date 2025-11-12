# Zybo Z7-20 AXI-ALU with PetaLinux (Bare-metal Memory Access)

이 프로젝트는 **Zybo Z7-20 (Zynq-7020)** 보드에서 Vivado로 생성한 **AXI-Lite 기반 ALU IP**를  
**PetaLinux 사용자 공간(/dev/mem)** 에서 직접 접근하여 테스트하는 예제입니다.  
커널 드라이버 없이, 메모리 매핑 방식으로 AXI 레지스터를 제어합니다.
<img width="1137" height="408" alt="image" src="https://github.com/user-attachments/assets/2993a0ba-942b-49ee-a85e-303aea440d66" />

-------
## 📁 프로젝트 구조

```
zybo_alu_project/
├── vivado_ip/
│   ├── alu_v1_0.v
│   ├── alu_v1_0_S00_AXI.v      # 수정된 AXI 슬레이브 파일 (ALU 연결 포함)
│   └── alu.v                   # 간단한 산술연산 모듈
├── petalinux_app/
│   ├── tb_project.c              # /dev/mem 접근용 C 테스트 프로그램
└── README.md                   # (현재 문서)
```

---

## 🧩 1. Vivado Design 개요

### 🔹 Block Diagram 구성
- **Zynq Processing System (PS7)**  
  - M_AXI_GP0 인터페이스 활성화  
- **ALU IP (axi_alu_v1_0)**  
  - S_AXI 포트 → PS7 M_AXI_GP0 연결  
  - 인터럽트 불필요  
- **Address Editor**  
  - ALU IP Base Address: `0x43C0_0000`
  - Range: 64 KB
 
## 💻 2. Vivado → Bitstream → PetaLinux Flow

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

## 🧠 3. 레지스터 맵

| 주소(Offset) | 이름 | 설명 | 접근 |
|---------------|-------|------|-------|
| 0x00 | **REG0** | `{a[31:24], b[23:16], …, ena[3], opcode[2:0]}` | RW |
| 0x04 | **REG1** | `{16'h0, result[15:0]}` (ALU 결과) | **RO** |
| 0x08 | **REG2** | Reserved | RW |
| 0x0C | **REG3** | Reserved | RW |

> ⚠️ REG1은 AXI 쓰기 금지. ALU enable(ena=1)일 때만 결과가 래치됩니다.

---
