
# Digilent Zybo Z7-20 PetaLinux : PS GPIO

## Zybo MIO GPIO Test

```
# /home/root/test_gpio.sh
#!/bin/sh
```

---

```
echo "=== GPIO Test ==="

# LED 초기화
echo 913 > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio913/direction

# 스위치 초기화
echo 956 > /sys/class/gpio/export 2>/dev/null
echo in > /sys/class/gpio/gpio956/direction
echo 957 > /sys/class/gpio/export 2>/dev/null
echo in > /sys/class/gpio/gpio957/direction

```

<img width="573" height="426" alt="image" src="https://github.com/user-attachments/assets/7022e479-759f-4721-82ae-faa12481025f" />

<img width="651" height="83" alt="image" src="https://github.com/user-attachments/assets/902878de-94dc-47c4-9934-cf8a0fc5d533" />


```
# LED 깜빡임 테스트
echo "LED Blinking Test..."
for i in 1 2 3 4 5; do
    echo 1 > /sys/class/gpio/gpio913/value
    sleep 0.5
    echo 0 > /sys/class/gpio/gpio913/value
    sleep 0.5
done

# 스위치 읽기
echo "Press switches (Ctrl+C to exit)..."
while true; do
    SW0=$(cat /sys/class/gpio/gpio956/value)
    SW1=$(cat /sys/class/gpio/gpio957/value)
   
    if [ "$SW0" = "0" ]; then
        echo "SW0 pressed - LED ON"
        echo 1 > /sys/class/gpio/gpio913/value
    elif [ "$SW1" = "0" ]; then
        echo "SW1 pressed - LED OFF"
        echo 0 > /sys/class/gpio/gpio913/value
    fi
   
    sleep 0.1
done
```

---

```
chmod +x /home/root/test_gpio.sh
```

---

```
./test_gpio.sh
```

```
Linux GPIO 번호 = 906 + MIO 번호

따라서:
- **MIO 7**  → GPIO **913** (906 + 7)
- **MIO 50** → GPIO **956** (906 + 50)
- **MIO 51** → GPIO **957** (906 + 51)

## 왜 906을 더하나?

Zynq-7000의 GPIO 컨트롤러 구조:
GPIO Bank 0 (MIO):  GPIO 906 ~ 959 (MIO 0-53)
GPIO Bank 1 (MIO):  GPIO 960 ~ 1023 (MIO 54-117)
GPIO Bank 2 (EMIO): GPIO 1024 ~ 1087 (EMIO 0-63)
GPIO Bank 3 (EMIO): GPIO 1088 ~ 1151 (EMIO 64-127)
```

```
# gpiochip 정보 확인
 ls /sys/class/gpio/
export       gpio913      gpio956      gpio957      gpiochip906  unexport

# GPIO 컨트롤러 정보
root@myproject:~# cat /sys/class/gpio/gpiochip906/label
zynq_gpio
root@myproject:~# cat /sys/class/gpio/gpiochip906/base
906
root@myproject:~# cat /sys/class/gpio/gpiochip906/ngpio
118
```

```c
// gpio_test.c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define GPIO_LED 913    // MIO 7
#define GPIO_SW0 956    // MIO 50
#define GPIO_SW1 957    // MIO 51

void gpio_export(int gpio) {
    int fd = open("/sys/class/gpio/export", O_WRONLY);
    char buf[10];
    sprintf(buf, "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
}

void gpio_direction(int gpio, const char *dir) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/direction", gpio);
    int fd = open(path, O_WRONLY);
    write(fd, dir, strlen(dir));
    close(fd);
}

void gpio_write(int gpio, int value) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(path, O_WRONLY);
    char buf[2] = {value + '0', '\0'};
    write(fd, buf, 1);
    close(fd);
}

int gpio_read(int gpio) {
    char path[50], buf[2];
    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(path, O_RDONLY);
    read(fd, buf, 1);
    close(fd);
    return buf[0] - '0';
}

int main() {
    // GPIO 초기화
    gpio_export(GPIO_LED);
    gpio_export(GPIO_SW0);
    gpio_export(GPIO_SW1);
    
    usleep(100000);  // export 후 대기
    
    gpio_direction(GPIO_LED, "out");
    gpio_direction(GPIO_SW0, "in");
    gpio_direction(GPIO_SW1, "in");
    
    printf("GPIO Test - Press switches to control LED\n");
    
    while(1) {
        int sw0 = gpio_read(GPIO_SW0);
        int sw1 = gpio_read(GPIO_SW1);
        
        if(sw0 == 0) {  // 스위치 눌림 (일반적으로 active low)
            gpio_write(GPIO_LED, 1);
            printf("SW0 pressed - LED ON\n");
        } else if(sw1 == 0) {
            gpio_write(GPIO_LED, 0);
            printf("SW1 pressed - LED OFF\n");
        }
        
        usleep(100000);  // 100ms 대기
    }
    
    return 0;
}
```

```c
// gpio_test.c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define GPIO_LED 913    // MIO 7

void gpio_export(int gpio) {
    int fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) {
        perror("Failed to open export");
        return;
    }
    char buf[10];
    sprintf(buf, "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
}

void gpio_unexport(int gpio) {
    int fd = open("/sys/class/gpio/unexport", O_WRONLY);
    if (fd < 0) {
        perror("Failed to open unexport");
        return;
    }
    char buf[10];
    sprintf(buf, "%d", gpio);
    write(fd, buf, strlen(buf));
    close(fd);
}

void gpio_direction(int gpio, const char *dir) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/direction", gpio);
    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("Failed to set direction");
        return;
    }
    write(fd, dir, strlen(dir));
    close(fd);
}

void gpio_write(int gpio, int value) {
    char path[50];
    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("Failed to write value");
        return;
    }
    char buf[2] = {value + '0', '\0'};
    write(fd, buf, 1);
    close(fd);
}

int main() {
    int led_state = 0;
    int count = 0;
    
    printf("=== LED Toggle Test ===\n");
    printf("MIO 7 (GPIO 913) will toggle continuously\n");
    printf("Press Ctrl+C to exit\n\n");
    
    // 기존 export가 있을 수 있으니 먼저 unexport 시도
    gpio_unexport(GPIO_LED);
    usleep(100000);
    
    // GPIO 초기화
    gpio_export(GPIO_LED);
    usleep(500000);  // export 후 충분한 대기 (500ms)
    
    gpio_direction(GPIO_LED, "out");
    usleep(100000);
    
    printf("Starting LED toggle...\n");
    
    // LED 계속 토글
    while(1) {
        led_state = !led_state;
        gpio_write(GPIO_LED, led_state);
        
        if (led_state) {
            printf("[%d] LED ON\n", count);
        } else {
            printf("[%d] LED OFF\n", count);
        }
        
        count++;
        usleep(500000);  // 500ms 대기 (0.5초마다 토글)
    }
    
    // 정리 (Ctrl+C로 종료되므로 실행되지 않음)
    gpio_write(GPIO_LED, 0);
    gpio_unexport(GPIO_LED);
    
    return 0;
}
```

```
arm-linux-gnueabihf-gcc -o gpio_test gpio_test.c
# 보드에 복사 후
./gpio_test
```
