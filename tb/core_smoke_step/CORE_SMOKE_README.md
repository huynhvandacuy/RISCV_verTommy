# RV32I: kiểm tra WB->ID và forwarding qua CPU

Chép ba thư mục tb/, sim/, sw/ vào project hiện tại. Gói này không thay RTL
hoặc Makefile. Cần bản RTL đã đổi tên, có top(clk_i, rst_ni), các instance
u_instr_mem/u_regfile và regfile đã thêm bypass như bước trước.

Đứng trong sim/:

```bash
make build tb_core_smoke core_smoke FILELIST=core_smoke.f
make run tb_core_smoke core_smoke
make wave tb_core_smoke core_smoke
```

core_smoke.f liệt kê các module core đang dùng, không compile rtl/ref/.
Không cần thay compile.f hoặc chạy script sinh file list cho case này.

## Test hoạt động thế nào?

1. Testbench override parameter instruction memory để đọc chương trình HEX.
2. Giữ reset trong ba chu kỳ rồi cho CPU chạy.
3. So sánh từng lần WB ghi thanh ghi với chín kết quả mong đợi, đúng thứ tự.
4. Sau end marker x9=1, kiểm tra trạng thái cuối của toàn bộ 32 thanh ghi.
5. In PASS và gọi $finish; nếu sai hoặc timeout thì gọi $fatal(1,...).

HEX là văn bản, mỗi dòng là một instruction 32 bit, không phải ELF.
core_smoke.S mô tả chương trình; HEX đã có sẵn nên chưa cần compiler.

Case bao gồm WB->ID, MEM->EX, WB->EX, forwarding cả hai toán hạng và
ưu tiên MEM hơn WB khi hai instruction cùng ghi một thanh ghi.

PASS chỉ xác nhận những case này. Load-use, load/store và branch/flush
sẽ có test riêng ở bước sau. Đây chưa phải kiểm tra toàn bộ RV32I.

## Kiểm tra đã thực hiện

Icarus: 41 kiểm tra PASS với regfile có bypass. Bản regfile cũ bị phát hiện
ở WB #1: x3=0 thay vì 6. Chưa chạy trực tiếp trên ModelSim.
