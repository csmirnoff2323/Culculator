unit MyDeque;

interface

type
  TElement = class // -- элемент списка
  public
    s: String;
    prev, next: TElement; // -- пред и следующий элемент  
    constructor Create;
  end;

  TStringProc = procedure (const s: String);

  // -- класс очереди (связный список)
  TMyDeque = class
  private
    listsize: Word;          // -- размер очереди
    left, right: TElement;   // =========> левая и правая ( начало и конец очереди )
  public
    constructor Create;
    destructor Destroy;override;
    procedure Clear;

    procedure Push_Left(const s: String); // -- добаление в начало очереди
    procedure Push_Right(const s: String); // -- добавление в конец очереди
    function Pop_Left: String;  // -- изътие из начала очереди
    function Pop_Right: String; // -- изътие из конца очереди
    function RightValue: String;
    function LeftValue: String;

    procedure ForEach(proc: TStringProc);
    procedure ForEachBack(proc: TStringProc);

    property Size: Word read listsize;
  end;

implementation

constructor TElement.Create;
begin
  s := '';
  next := nil;
  prev := nil;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TMyDeque.Create;
begin
  listsize := 0;
  Clear;
end;

procedure TMyDeque.Clear;
begin
  while size > 0 do
    Pop_Right;
  left := nil;
  right := nil;
end;

destructor TMyDeque.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TMyDeque.Push_Left(const s: String);
var
  tmp: TElement;
begin
  if size = 0 then
  begin
    left := TElement.Create;
    right := left;
    left.s := s;
  end else begin 
    tmp := left; // ---первый элемент
    left := TElement.Create; // -- новый элемент указывает на первый  
    left.s := s;
    left.next := tmp;
    tmp.prev := left; // -- первый элемент становиться вторым
  end;
  inc(listsize);
end;

procedure TMyDeque.Push_Right(const s: String); // ==========> добавить в право очереди ( в конец )
var
  tmp: TElement;
begin
  if size = 0 then
  begin
    left := TElement.Create;
    right := left;
    left.s := s;
  end else begin
    tmp := right;
    right := TElement.Create;
    right.s := s;
    right.prev := tmp;
    tmp.next := right;
  end;
  inc(listsize);
end;

function TMyDeque.Pop_Left: String;
var
  tmp: TElement;
begin
  Result := '';
  if size > 0 then
  begin
    Result := left.s;
    if left.next <> nil then
      left.next.prev := nil;
    tmp := left.next;
    left.Free;
    left := tmp;
    dec(listsize); // -- уменьшаем размер
  end;
end;

function TMyDeque.Pop_Right: String;
var
  tmp: TElement;
begin
  Result := '';
  if size > 0 then
  begin
    Result := right.s;
    if right.prev <> nil then
      right.prev.next := nil;
    tmp := right.prev;
    right.Free;
    right := tmp;
    dec(listsize);
  end;
end;

procedure TMyDeque.ForEach(proc: TStringProc);
var
  curr: TElement;
begin
  if Assigned(proc) then
  begin
    curr := left;
    if size > 0 then
      repeat
        proc(curr.s);
        curr := curr.next;// -- прокручиваем список
      until curr = nil;
  end;
end;

procedure TMyDeque.ForEachBack(proc: TStringProc);
var
  curr: TElement;
begin
  if Assigned(proc) then
  begin
    curr := right;
    if size > 0 then
      repeat
        proc(curr.s);
        curr := curr.prev;// -- прокручиваем список в обратном порядке
      until curr = nil;
  end;
end;

function TMyDeque.RightValue: String; // -- значение первого элемента
begin
  if right <> nil then
    Result := right.s
  else
    Result := '';
end;

function TMyDeque.LeftValue: String;  // -- значение последнего элемента
begin
  if left <> nil then
    Result := left.s
  else
    Result := '';
end;

end.
