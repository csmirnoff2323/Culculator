unit MyParser;

interface

uses
  MyDeque, SysUtils, Math, MyArr;

type
  TMyParser = class                  
  private
    deque: TMyDeque;
    s, cons, err: String; // -- s-строка cons-значения переменных  
    arr: TMyArr;          // -- массив (две очереди для имени и значения ) 
    function IsNumb(c: Char): Boolean;
    function IsOp(c: Char): Boolean;
    function IsBracket(c: Char): Boolean;
    function IsChar(c: Char): Boolean;
    function IsPoint(c: Char): Boolean;
    function IsValidSymbol(c: Char): Boolean;
    function IsValidFloat(const s: String): Boolean;
    function IsValidString(const s: String): Boolean;
    function IsValidConst(const s: String): Boolean;
    function IsFunc(s: String): Boolean;
    function Priority(a, b: Char): Boolean;
    function TestBrackets(const s: String): Boolean;
    procedure AddError(const s: String);
    function TestResult: Boolean;
    function CorrectStr(const s: String): String;
    function ExtractConstants: Boolean;
  public
    constructor Create(const s: String; const cons: String);
    destructor Destroy;override;
    function Parse(out outdeque: TMyDeque): Boolean;overload;
    function Parse: Boolean;overload;
    function Calc(out x: Extended; DegOrRad: Boolean): Boolean;
    property Errors: String read err;
  end;

implementation

constructor TMyParser.Create(const s: String; const cons: String);
begin
  err := '';
  deque := nil;

  // строка с формулой //
  self.s := CorrectStr(s);

  // константы //
  self.cons := cons;
end;

destructor TMyParser.Destroy;
begin
  arr.Free;
  deque.Free;
  Inherited;
end;

// получение списка констант //
function TMyParser.ExtractConstants: Boolean;
var
  tmp: String;
  i: Word;

  // добавление константы //
  function AddConst: Boolean;
  var
    a, b, c: String;
    j: Word;
  begin
    Result := True;
    if Length(tmp) > 0 then
    begin
      tmp := CorrectStr(tmp);
      a := ''; b := ''; c := '';
      for j := 1 to Length(tmp) do
      begin
        if (b = '') then
        begin
          if tmp[j] <> '=' then //
            a := a + tmp[j]
          else
            b := '=';
        end else
          c := c + tmp[j];
      end;

      // считывает a до тех пор пока не найдет =
      // считывает c до конца
       
      // a,b,c
      // a = 'a';
      // b = '=';
      // c = '1';

      if IsValidConst(a) and (b = '=') and IsValidFloat(c) then
        // ДОБАВЛЕНИЕ a,c
        arr.Add(a, StrToFloat(c))
      else begin
        Result := False;
        AddError('Ошибка: неправильно задана константа: ' + a + b + c);
      end;
      tmp := '';
    end;
  end;

begin
  Result := True;
  arr := TMyArr.Create;
  arr.Add('e', 2.718281828459045);
  arr.Add('pi', 3.141592653589793);
  if Length(cons) > 0 then
  begin
    i := 0;
    tmp := '';
    while i < Length(cons) do
    begin
      inc(i);
      if cons[i] <> ' ' then
        if (cons[i] = #13) or (cons[i] = #10) then
        begin
          if not AddConst then
          begin
            Result := False;
            break;
          end;
        end else
          tmp := tmp + cons[i];
    end;
    if Result then
      Result := AddConst;
  end;
end;

function TMyParser.CorrectStr(const s: String): String;
var
  c: Char;
  f: Extended;
  x: String;
  i: Word;
begin
  Result := '';
  if Length(s) > 0 then
  begin
    f := 1.1;
    x := FloatToStr(f);
    c := x[2];
    for i := 1 to Length(s) do
      if (s[i] <> ' ') and (s[i] <> Chr(13)) and (s[i] <> Chr(10)) then
        if (s[i] = '.') or (s[i] = ',') then
          Result := Result + c
        else if (s[i] <> '[') and (s[i] <> ']') then
          Result := Result + s[i]
        else if s[i] = '[' then
          Result := Result + '('
        else if s[i] = ']' then
          Result := Result + ')';

  end;
end;

function TMyParser.TestBrackets(const s: String): Boolean; // --
var
  tmp: TMyDeque;
  i: Word;
begin
  Result := True;
  if Length(s) > 0 then
  begin
    tmp := TMyDeque.Create; // -- новая очередь 
    for i := 1 to Length(s) do
    begin
      if s[i] = '(' then
        tmp.Push_Right('(')
      else if s[i] = ')' then
      begin
        if tmp.RightValue = '(' then
          tmp.Pop_Right
        else begin
          AddError('Ошибка: не хватает открывающей скобки');
          Result := False;
          break;
        end;
      end;
    end;
    if tmp.Size > 0 then
    begin
      AddError('Ошибка: не хватает закрывающей скобки');
      Result := False;
    end;
    tmp.Free;
  end;
end;

function TMyParser.IsFunc(s: String): Boolean; // --- проверка это функция
begin
  s := LowerCase(s);
  if (s = 'arccos') or (s = 'arccosh') or (s = 'arcctg') or
     (s = 'arcctgh') or (s = 'arccosec') or (s = 'arccosech') or
     (s = 'arcsec') or (s = 'arcsech') or (s = 'arcsin') or
     (s = 'arcsinh') or (s = 'arctg') or (s = 'arctgh') or
     (s = 'cos') or (s = 'cosec') or (s = 'cosh') or
     (s = 'ctg') or (s = 'ctgh') or
     (s = 'cosech') or (s = 'sec') or (s = 'sech') or
     (s = 'sin') or (s = 'sinh') or (s = 'tg') or (s = 'tgh') or
     (s = 'exp') or  (s = 'ln') or  (s = 'log') or (s = 'sqrt') or
     (s = 'degtorad') or (s = 'radtodeg') or (s = 'neg') or (s = 'round') or
     (s = 'ceil') or (s = 'floor') or (s = 'abs') then
    Result := True
  else
    Result := False;
end;

function TMyParser.Priority(a, b: Char): Boolean; // -- приоритет операторов 
begin
  if IsOp(b) and
     ((a = '@') or
     ((a = '^') and (b <>'@')) or
     (((a = '*') or (a = '/')) and (b <> '^')) or
     (((a = '+') or (a = '-')) and ((b = '+') or (b = '-')))) then
    Result := True
  else
    Result := False;
end;

function TMyParser.Calc(out x: Extended; DegOrRad: Boolean): Boolean; // ----> вычисление 
var
  stack, tmp, main: TMyDeque;
  s: String;

  function CalcOp: Extended; // ======> выполнение операции 
  var
    a, b: Extended; // -- переменные a и b
    op: String;

    procedure StackUnderflow;
    begin
      AddError('Ошибка: в стеке ничего нет');
    end;

  begin
    Result := 0;

    try
    if stack.Size > 0 then
    begin
      op := stack.Pop_Right; // ---- вытаскиваем из конца знак "+-*/" ( ab+)
      if IsOp(op[1]) and (op[1] <> '@') then
      begin
        if stack.Size > 0 then
        begin
          b := StrToFloat(stack.Pop_Right); // -- два операнда a и b
          if stack.Size > 0 then
          begin
            a := StrToFloat(stack.Pop_Right);
            case op[1] of
              '+': a := a + b;
              '-': a := a - b;
              '*': a := a * b;
              '/': if b <> 0 then
                     a := a / b
                   else begin
                     a := 0;
                     AddError('Ошибка: деление на ноль');
                   end;
              '^': a := Power(a, b);
            end;
            Result := a;
          end else // -- очередь пуста
            StackUnderflow;
        end else
          StackUnderflow;
      end else if op[1] = '@' then
      begin
        if stack.Size > 0 then
        begin
          a := StrToFloat(stack.Pop_Right);
          a := -a;
          Result := a;
        end else
          StackUnderflow;
      end else if IsFunc(op) then // -- функция
      begin
        if stack.Size > 0 then
        begin
          a := StrToFloat(stack.Pop_Right);
          op := LowerCase(op);
          if DegOrRad then
            b := DegToRad(a)
          else b := a;
          if op = 'cos' then
            a := Cos(b)
          else if op = 'cosec' then
            a := Cosecant(b)
          else if op = 'cosh' then
            a := CosH(b)
          else if op = 'ctg' then
            a := Cotan(b)
          else if op = 'ctgh' then
            a := CotH(b)
          else if op = 'tgh' then
            a := TanH(b)
          else if op = 'cosech' then
            a := CscH(b)
          else if op = 'sec' then
            a := Sec(b)
          else if op = 'sech' then
            a := SecH(b)
          else if op = 'sin' then
            a := Sin(b)
          else if op = 'sinh' then
            a := SinH(b)
          else if op = 'tg' then
            a := Tan(b) else
          if (op = 'arccos') or (op = 'arccosh') or (op = 'arcctg') or
             (op = 'arcctgh') or (op = 'arccosec') or (op = 'arccosech') or
             (op = 'arcsec') or (op = 'arcsech') or (op = 'arcsin') or
             (op = 'arcsinh') or (op = 'arctg') or (op = 'arctgh') then
          begin
            if (op = 'arccos') then
              a := ArcCos(a)
            else if (op = 'arccosh') then
              a := ArcCosH(a)
            else if (op = 'arcctg') then
              a := ArcCot(a)
            else if (op = 'arcctgh') then
              a := ArcCotH(a)
            else if (op = 'arccosec') then
              a := ArcCsc(a)
            else if (op = 'arccosech') then
              a := ArcCscH(a)
            else if (op = 'arcsec') then
              a := ArcSec(a)
            else if (op = 'arcsech') then
              a := ArcSecH(a)
            else if (op = 'arcsin') then
              a := ArcSin(a)
            else if (op = 'arcsinh') then
              a := ArcSinH(a)
            else if (op = 'arctg') then
              a := ArcTan(a)
            else if (op = 'arctgh') then
              a := ArcTanH(a);
            if DegOrRad then
              a := RadToDeg(a);
          end
          else if op = 'exp' then
            a := exp(a)
          else if op = 'ln' then
            a := Ln(a)
          else if op = 'log' then
            a := Log10(a)
          else if op = 'ceil' then
            a := Ceil(a)
          else if op = 'floor' then
            a := Floor(a)
          else if op = 'round' then
            a := Round(a)
          else if op = 'radtodeg' then
            a := RadToDeg(a)
          else if op = 'abs' then
            a := Abs(a)
          else if op = 'neg' then
            a := -a
          else if op = 'degtorad' then
            a := DegToRad(a)
          else if op = 'sqrt' then
            if a >= 0 then
              a := sqrt(a)
            else begin
              a := 0;
              AddError('Ошибка: извлечение квадратного корня из отрицательного числа');
            end;
          Result := a;
        end else
          StackUnderflow;
      end;
    end else
      StackUnderflow;

    except
      AddError('Ошибка в вычислениях');
    end;
  end;

begin
  Result := False;
  x := 0;
  if deque <> nil then   // ============> очередь не nil
  begin
    if deque.Size > 0 then  // ---- очередь не пуста
    begin
      stack := TMyDeque.Create;
      main := TMyDeque.Create;
      tmp := TMyDeque.Create;

      while deque.Size > 0 do  // =====> пишем в tmp и main 
      begin
        s := deque.Pop_Left;
        tmp.Push_Right(s);
        main.Push_Right(s);
      end;
      deque.Free;
      deque := tmp;  // ----------> новая очередь
      // -- tmp и main содержат копию deque

      tmp := TMyDeque.Create; // ------------- для записи операций "+-*/" потом операции прокуручиваются в очереди

      while (main.Size > 0) and (Length(errors) = 0) do
      begin
        s := main.Pop_Left;// -- вытаскиваем первый элемент очереди

        if Length(s) > 0 then
          if IsValidFloat(s) then
            stack.Push_Right(s)
          else if IsBracket(s[1]) then
          begin
            if s[1] = '(' then
              tmp.Push_Right(s)
            else begin
              while (tmp.Size > 0) and (tmp.RightValue <> '(') do
              begin
                stack.Push_Right(tmp.Pop_Right);
                stack.Push_Right(FloatToStr(CalcOp)); // ==========> вычисление
              end;
              tmp.Pop_Right;
            end;
          end else if IsFunc(s) then
            tmp.Push_Right(s)
          else if IsOp(s[1]) then // -- оператор "+-/*"
          begin
            if (tmp.Size = 0) or (tmp.RightValue = '(') then
              tmp.Push_Right(s)
            else if Priority(s[1], tmp.RightValue[1]) then // -- проверка приоритета операторов "+" "*"
              tmp.Push_Right(s) // -- приоритет правильный 
            else begin // -- приотритет оператора ниже
              while (tmp.Size > 0) and
                    (not Priority(s[1], tmp.RightValue[1])) and
                    (tmp.RightValue <> '(') do
              begin
                stack.Push_Right(tmp.Pop_Right);
                stack.Push_Right(FloatToStr(CalcOp)); // ==========> вычисление
              end;
              tmp.Push_Right(s);
            end;
          end else if IsValidConst(s) then // -- переменная 
          begin
            if arr.IsExists(s) then // -- проверка наличия переменной  
              stack.Push_Right(FloatToStr(arr.GetValue(s))) // ==========> записываем значение переменной ( a или b )
            else
              AddError('Ошибка: неопределённая константа: ' + s);
          end else begin
            AddError('Ошибка: неизвестная операция:  ' + s);
          end;
      end;

      // ba+ 
  	  // ba+ cd * fg  ======> формат хранения в очереди для вычисления
  	  // +151 - вычисляем 1+5=6 добавляем 6 назад в стек
  	  // +61  - вычисляем 6+1=7 добавляем 7 назад в стек
  	  // результат 7 

  	  // - первой идет символ операции "+-*/"
  	  // - вторыми идут два операнда которые будут вычисляться
	    //

      while (tmp.Size > 0) and (Length(errors) = 0) do
      begin
        stack.Push_Right(tmp.Pop_Right);      // ---- операции "+-*/"
        stack.Push_Right(FloatToStr(CalcOp)); // ==========> вычисление ( при это стек очищается от операндов a и b )
        // -- результат добавляется в очередь
        // -- повтор цикла ( добавление оператора "+-*/" )     
      end;

      while (stack.Size > 1) and (Length(errors) = 0) do
        stack.Push_Right(FloatToStr(CalcOp)); // ==========> вычисление
      if Length(errors) = 0 then
      begin
        Result := True;
        x := StrToFloat(stack.Pop_Right);
      end else begin
        Result := False;
        x := 0;
      end;

      tmp.Free;
      main.Free;
      stack.Free;
      
    end else
      AddError('Ошибка: нет строки для вычислений');
  end else
    AddError('Ошибка: нет строки для вычислений');
  if Length(errors) > 0 then
    Result := False;
end;

function TMyParser.TestResult: Boolean;
type
  TMyType = (NULL, OP, NUM, CONS, FUNC, BRACKL, BRACKR); // -- тип символа слова "оператор","число","константа","функция","скобка" левая правая 
var
  tmp, new: TMyDeque;
  s, prevs: String;
  prev: TMyType;

  function GetMyType(const s: String): TMyType;// определение типа символа знака функции переменной 
  begin
    Result := NULL;
    if Length(s) > 0 then
    begin
      if IsOp(s[1]) then
        Result := OP
      else if IsValidFloat(s) then
        Result := NUM
      else if IsFunc(s) then
        Result := FUNC
      else if IsValidConst(s) then
        Result := CONS
      else if s[1] = '(' then
        Result := BRACKL
      else if s[1] = ')' then
        Result := BRACKR
      else
        AddError('Ошибка: неправильный идентификатор: ' + s);
    end;
  end;

begin

  Result := True;

  // -- две очереди в которые мы записываем deque (tmp временная ) ( знак "-" заменяется на @ )
  tmp := TMyDeque.Create;
  new := TMyDeque.Create;

  prevs := '';
  while deque.Size > 0 do // =======> очередь заполнена
  begin
    s := deque.Pop_Left;  // -- вытаскиваем из начала

    if s = '-' then // - знак "-"
    begin
      if prevs = '' then // пред символ ""
        s := '@'
      else if IsOp(prevs[1]) or (prevs[1] = '(') then // пред символ "("
        s := '@';
    end;
    tmp.Push_Right(s);
    new.Push_Right(s);
    prevs := s;
  end;

  deque.Free;

  deque := new; // === новая очередь
  prev := NULL;
  prevs := '';

  while tmp.Size > 0 do // --- проверяем временную очередь ( ошибки ) 
  begin
    s := tmp.Pop_Left;  // ==========> вытаскиваем первый элемент очереди
    case GetMyType(s) of
    OP:   begin
        if (prev = NULL) then
          if s <> '@' then
          begin
            AddError('Ошибка: пропущен операнд:   ' + prevs + ' ' + s);
            Result := False;
          end;
        if (prev = OP) then
          if s <> '@' then
          begin
            AddError('Ошибка: два оператора подряд:   ' + prevs + ' ' + s);
            Result := False;
          end;
        if (prev = FUNC) then
        begin
          AddError('Ошибка: пропущена скобка после имени функции:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = BRACKL) then
          if s <> '@' then
          begin
            AddError('Ошибка: оператор после скобки:   ' + prevs + ' ' + s);
            Result := False;
          end;
      end;
    NUM:  begin
        if (prev = NUM) then
        begin
          AddError('Ошибка: два числа подряд:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = FUNC) then
        begin
          AddError('Ошибка: пропущена открывающая скобка:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = CONS) then
        begin
          AddError('Ошибка: константа перед числом:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = BRACKR) then
        begin
          AddError('Ошибка: закрывающая скобка перед числом:   ' + prevs + ' ' + s);
          Result := False;
        end;
      end;
    FUNC: begin
        if (prev = NUM) then
        begin
          AddError('Ошибка: пропущен оператор:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = FUNC) then
        begin
          AddError('Ошибка: два имени функции подряд:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = CONS) then
        begin
          AddError('Ошибка: пропущен оператор:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = BRACKR) then
        begin
          AddError('Ошибка: пропущен оператор:   ' + prevs + ' ' + s);
          Result := False;
        end;
      end;
    CONS: begin
        if (prev = NUM) or (prev = CONS) or (prev = BRACKR) then
        begin
          AddError('Ошибка: пропущен оператор:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = FUNC) then
        begin
          AddError('Ошибка: пропущена открывающая скобка:   ' + prevs + ' ' + s);
          Result := False;
        end;
      end;
    BRACKL:begin
        if (prev = NUM) or (prev = CONS) then
        begin
          AddError('Ошибка: пропущен оператор:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = BRACKR) then
        begin
          AddError('Ошибка: две скобки:   ' + prevs + ' ' + s);
          Result := False;
        end;
      end;
    BRACKR:begin
        if (prev = OP) then
        begin
          AddError('Ошибка: оператор перед закрывающей скобкой:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = FUNC) then
        begin
          AddError('Ошибка: функция перед закрывающей скобкой:   ' + prevs + ' ' + s);
          Result := False;
        end;
        if (prev = BRACKL) then
        begin
          AddError('Ошибка: две скобки:   ' + prevs + ' ' + s);
          Result := False;
        end;
      end;
    end;
    prev := GetMyType(s);
    prevs := s;
  end;
  if Length(errors) > 0 then // --- есть ошибки выходим
    Result := False;
  tmp.Free; // -- удаляем временную очередь
end;

function TMyParser.Parse: Boolean;
var
  tmp: TMyDeque;
begin
  Result := Parse(tmp);
end;

function TMyParser.Parse(out outdeque: TMyDeque): Boolean; // ===============> получение очереди и ее проверки
var
  tmp: String;
  i: Word;

  function FlushTemp: Boolean;
  var
    ValBool:Boolean;
  begin
    Result := True;
    if Length(tmp) > 0 then
    begin
      ValBool:= IsValidConst(tmp);
      ValBool:=IsValidFloat(tmp);

      if IsValidConst(tmp) or IsValidFloat(tmp) then
      begin
        deque.Push_Right(tmp);
      end else begin
        AddError('Ошибка: неправильный идентификатор: ' + tmp);
        Result := False;
      end;
      tmp := '';
    end;
  end;

begin
  deque := TMyDeque.Create; // ============> создание очереди
  Result := True;
  tmp := '';
  if Length(s) = 0 then
    AddError('Ошибка: не введена строка')
  else if not IsValidString(s) then
    AddError('Ошибка: строка содержит недопустимые символы')
  else if TestBrackets(s) then
  if ExtractConstants then begin
    for i := 1 to Length(s) do
    begin
      if IsOp(s[i]) or IsBracket(s[i]) then // ----- оператор + - или "["
      begin
        if not FlushTemp then break;
        deque.Push_Right(s[i]);
      end else
        if IsNumb(s[i]) or IsPoint(s[i]) or IsChar(s[i]) then
          tmp := tmp + s[i];
    end;
    FlushTemp;  // ============> проверка Tmp
    if Length(errors) > 0 then
      Result := False;
    if Result then
      Result := TestResult;// ==========> проверка очереди
    outdeque := deque;   // ============> выходной параметер
  end;
  if Length(errors) > 0 then
    Result := False;
end;

function TMyParser.IsNumb(c: Char): Boolean; // проверка числа от "0" до "9" 
begin
  if ((c >= '0') and (c <= '9')) then
    Result := True
  else
    Result := False;
end;

function TMyParser.IsOp(c: Char): Boolean; // оператор плюс "+" минус "-" умножить "*", разделить "/"
const
  ops = '+-*/^@';
var
  i: Byte;
begin
  Result := False;
  for i := 1 to Length(ops) do
    if ops[i] = c then
    begin
      Result := True;
      break;
    end;
end;

function TMyParser.IsBracket(c: Char): Boolean; // проверка скобок 
begin
  if (c = '(') or (c = ')') then
    Result := True
  else
    Result := False;
end;

function TMyParser.IsChar(c: Char): Boolean; // проверка на символ от "a" до "z" и от "A" до "Z"
begin
  if ((c >= 'a') and (c <= 'z')) or
     ((c >= 'A') and (c <= 'Z')) or
     (c = '_') then
    Result := True
  else
    Result := False;
end;

function TMyParser.IsPoint(c: Char): Boolean; // проверка разделителя точка "." запятая ","
begin
  if (c = '.') or (c = ',') then
    Result := True
  else
    Result := False;
end;

function TMyParser.IsValidFloat(const s: String): Boolean; // проверка дробного
var
  i: Word;
  p: Word;
begin
  Result := True;
  if Length(s) > 0 then
  begin
    p := 0;
    for i := 1 to Length(s) do
    begin
      if not IsNumb(s[i]) then
        if IsPoint(s[i]) then
          inc(p)
        else begin
          Result := False;
          break;
        end;
    end;
    if p > 1 then
      Result := False;
  end else
    Result := False;
end;

function TMyParser.IsValidSymbol(c: Char): Boolean;
begin
  if IsNumb(c) or IsOp(c) or IsBracket(c) or IsChar(c) or IsPoint(c) then
    Result := True
  else
    Result := False;
end;

function TMyParser.IsValidString(const s: String): Boolean;  // ========> проверка строки s 
var
  i: Word;
begin
  Result := True;
  if Length(s) > 0 then
  begin
    for i := 1 to Length(s) do
      if not IsValidSymbol(s[i]) then
      begin
        Result := False;
        break;
      end;
  end else
    Result := False;
end;

function TMyParser.IsValidConst(const s: String): Boolean; // -- переменная 
var
  i: Word;
begin
  Result := True;
  if Length(s) = 0 then
    Result := False
  else if IsNumb(s[1]) then
    Result := False
  else if not IsChar(s[1]) then
    Result := False
  else if Length(s) > 1 then
    for i := 2 to Length(s) do
      if (not IsChar(s[i])) and (not IsNumb(s[i])) then
        Result := False;
end;

procedure TMyParser.AddError(const s: String); // -- добавление ошибки
begin
  if Length(err) <> 0 then
    err := err + #13#10;  // -- CRLF 
  err := err + s;
end;

end.
