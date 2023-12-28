module APB_generator
#(parameter control_reg_ADDR = 4'h0, // адрес контрольного регистра
  parameter status_ADDR = 4'h4)    // адрес регистра статуса
(
    input wire PWRITE,            // сигнал, выбирающий режим записи или чтения (1 - запись, 0 - чтение)
    input wire PCLK,              // сигнал синхронизации
    input wire PSEL,              // сигнал выбора переферии 
    input wire [31:0] PADDR,             // Адрес регистра
    input wire [31:0] PWDATA,     // Данные для записи в регистр
    output reg [31:0] PRDATA = 0, // Данные, прочитанные из регистра
    input wire PENABLE,           // сигнал разрешения
    output reg PREADY = 0,         // сигнал готовности (флаг того, что всё сделано успешно)
	  input PRESET,                   // сигнал сброса
    output reg CLK = 0                    // выходной сигнал генератора синхросигнала
);


reg  [31:0] control_reg  = 0;  // регистр, который задаёт длительность периода синхросигнала
reg  [31:0] status = 0;        // регистр, который отражает текущее значение выхода и текущее значение счётчика
reg  [31:0] counter = 0;       // счётчик генератора синхросигнала
reg flag = 0;                  // флаг, который показывает, что изменилось значение контрольгого регистра

always @(posedge PCLK) 
begin
    
    if (PSEL && !PWRITE && PENABLE) // Чтение из регистров 
     begin
        case(PADDR)
         control_reg_ADDR : PRDATA <= control_reg; // чтение по адресу контрольного регистра
         status_ADDR      : PRDATA <= status;  // чтение по адресу регистра статуса
        endcase
        PREADY <= 1'd1; // поднимаем флаг заверешения операции
     end

     else if(PSEL && PWRITE && PENABLE) // запись производится только в контрольный регистр
     begin
      if(PADDR == control_reg_ADDR)
      begin
        control_reg <= PWDATA;
        flag <= 1'd1;         // поднимаем флаг изменения контрольного регистра
        PREADY <= 1'd1;       // поднимаем флаг заверешения операции
      end
     end
   
   if (PREADY) // сбрасываем PREADY после выполнения записи или чтения
    begin
      PREADY <= !PREADY;
    end

  if(flag)  // сбрасываем флаг после выполнения записи в счётчик
    begin
      flag <= !flag;
    end
  end


always @(posedge PCLK) begin // работа генератора синхросигнала

   if(flag)
   begin
    counter <= control_reg[31:1]; // 0 бит контрольного регистра будет отвечать за старт/стоп
    status[31:1] <= control_reg[31:1];
   end

  else if(control_reg[0] == 1) // если значение младшего разряда равно 1, то генератор начинает свою работу
   begin
     if(counter > 0) // если текущее значение счётчика больше 0, то производим отсчёт
      begin
      counter <= counter - 1'd1;
      status[31:1] <= counter - 1'd1;
     end

   end


    if(counter == 0 && control_reg[0] == 1) // если значение счётчика равно 0, то меняем значение CLK и обновляем счётчик
    begin
      counter <= control_reg[31:1];
      CLK <= !CLK;

      status[31:1] <= control_reg[31:1];
      status[0]    <= !CLK;
    end
end

//iverilog -g2012 -o APB_generator.vvp APB_generator_tb.sv
//vvp APB_generator.vvp
endmodule