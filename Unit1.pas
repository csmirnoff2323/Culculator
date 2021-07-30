unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,
  StdCtrls,
  MyDeque,
  MyParser, ComCtrls, XPMan;

type
  TForm1 = class(TForm)
    vebbDig1: TButton;
    vebbDig2: TButton;
    vebbDig3: TButton;
    vebbDig4: TButton;
    vebbDig5: TButton;
    vebbDig6: TButton;
    vebbDig7: TButton;
    vebbDig8: TButton;
    vebbDig9: TButton;
    vebbMul: TButton;
    vebbMinus: TButton;
    vebbPlus: TButton;
    vebbDig0: TButton;
    vebbPoint: TButton;
    editValue: TEdit;
    vebbBkSp: TButton;
    Label_e: TLabel;
    vebbCulc: TButton;
    txtResult: TRichEdit;
    XPManifest1: TXPManifest;
    vebbClear: TButton;
    vebbDev: TButton;
    vebbBrkl: TButton;
    vebbBrkr: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure vebbCulcClick(Sender: TObject);
    procedure vebbClearClick(Sender: TObject);
  private
	 valueInt : integer;
   valueFloat : single;
	 valueMin, valueMax : single;
	 valueStr : String;
   CurrResult : Extended;
   deque : TMyDeque;
   parser : TMyParser; // -- парсер формул

   { Private declarations }
  public
    { Public declarations }
  published
   procedure OnClickBtn(Sender : TObject);
   procedure vebbBkSpClick(Sender:TObject);
   procedure editValueKeyPress(Sender:TObject; var Key: Char);
   procedure vebbEnterClick( Sender : TObject);
   procedure vebbPointClick(Sender:TObject);
  end;

var
  Form1: TForm1;

// -- форма используется для ввода значений
// и получение введенного значения 

implementation

{$R *.dfm}

procedure TForm1.vebbPointClick(Sender:TObject); // -- символ "."
var
	w:String;
begin
	w:= StringOfChar(DecimalSeparator,1);  // символ '-'
  //w:= w _
	if( editValue.Text = ''  ) 					// если точка идет первым символом
  then
  begin
		editValue.Text:= '0'+w; // -- если "" ставим "0."
  end
	else if ( Pos(w,editValue.Text) = 0 ) 	// раньше точки не было
  then
  begin
		editValue.Text:= editValue.Text+w;
	end;
  
end;

procedure TForm1.vebbEnterClick( Sender : TObject); // -- enter ?????
begin

end;

procedure TForm1.editValueKeyPress(Sender:TObject; var Key: Char);
label labelNum;
var
 	kl:char;
  pos:integer;
  str:String;
begin
 	kl:= Key;

  if kl in ['0'.. '9'] then
  begin
    exit;
  end
  else if (kl = '+') or (kl = '-') or (kl = '/') or (kl = '*') or (kl = ',') or (kl = '.' ) then
  begin
    exit;
  end
  else if kl in ['{'] then
  begin
    exit;
  end
  else if kl in ['}'] then
  begin
    exit;
  end
  else if kl in ['['] then
  begin
    exit;
  end
  else if kl in [']'] then
  begin
    exit;
  end
  else if kl in ['('] then
  begin
    exit;
  end
  else if kl = #8 then
  begin // -- back space
      exit;
  end
  else if kl in [')'] then
  begin
    exit;
  end
	else
  begin
     Key:=chr(0);
  end;

end;

procedure TForm1.vebbBkSpClick(Sender:TObject); //-- кнопка "backspace"
var
	str:String;
  pos: Word;
begin
	str:= editValue.Text;
  pos:= editValue.SelStart;

	if Length(str) > 0 then // -- есть данные
  begin
    System.Delete(str,pos,1);
  end;

	editValue.Text:= str;
  editValue.SelStart := pos + Length((Sender as TButton).Caption);
end;

//---------------------------------------------------------------------------
procedure TForm1.OnClickBtn(Sender : TObject); // -- нажатие на кнопку 0..9 +-/*
var
	str : String;
  btn : TButton;
  tmp: String;
  i: Word;
  pos: Word;
begin
  str:= TButton(Sender).Caption;
  pos := editValue.SelStart;
  for i := 1 to editValue.SelStart do
    tmp := tmp + editValue.Text[i];
  tmp := tmp + (Sender as TButton).Caption;
  if editValue.SelStart < Length(editValue.Text) then
    for i := editValue.SelStart + 1 to Length(editValue.Text) do
      tmp := tmp + editValue.Text[i];
  editValue.Text := tmp;
  editValue.SelStart := pos + Length((Sender as TButton).Caption);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // -- не используется
	valueStr:=		'';
	valueInt:=		0;
	valueFloat:=	0;
	valueMin:= 	-9e9;
	valueMax:= 	9e9;

  // -- кнопки 0..9 +-/*
  self.vebbDig0.OnClick:=OnClickBtn;
  self.vebbDig1.OnClick:=OnClickBtn;
  self.vebbDig2.OnClick:=OnClickBtn;
  self.vebbDig3.OnClick:=OnClickBtn;
  self.vebbDig4.OnClick:=OnClickBtn;
  self.vebbDig5.OnClick:=OnClickBtn;
  self.vebbDig6.OnClick:=OnClickBtn;
  self.vebbDig7.OnClick:=OnClickBtn;
  self.vebbDig8.OnClick:=OnClickBtn;
  self.vebbDig9.OnClick:=OnClickBtn;
  self.vebbPlus.OnClick:=OnClickBtn;
  self.vebbMinus.OnClick:= OnClickBtn;
  self.vebbPoint.OnClick:= OnClickBtn;
  self.vebbMul.OnClick:= OnClickBtn;
  self.vebbDev.OnClick:= OnClickBtn;
  self.vebbBrkl.OnClick:= OnClickBtn;
  self.vebbBrkr.OnClick:= OnClickBtn;

  self.vebbBkSp.OnClick:=vebbBkSpClick;
  self.editValue.OnKeyPress:=editValueKeyPress;

  self.Label_e.Visible:=false;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  valueInt:=0;
	valueFloat:=0;
	valueStr:='';

	if( Length(editValue.Text) > 0 ) then // -- есть данные
  begin
		valueStr:= editValue.Text;
		editValue.SelectAll();
	end;

  // -- выделенная позиция
  editValue.SelStart :=Length(editValue.Text);
end;

// - вычисление
procedure TForm1.vebbCulcClick(Sender: TObject);
var
  x: Extended;
begin
  txtResult.Text := '';

  parser := TMyParser.Create(editValue.Text, '');

  // -- editValue - формула, второй параметр - значение переменных подставляемыех в формулу (передается строкой )
  // -- установка значений

  // deque - пуст
  if parser.Parse(deque) then
  begin
    if parser.Calc(x, false) then // -- вычисление
    begin
      txtResult.Text := FloatToStr(x);
      CurrResult := x;
    end else
      txtResult.Text := parser.Errors;
  end else
    txtResult.Text := parser.Errors;

end;

procedure TForm1.vebbClearClick(Sender: TObject);
begin
  // --
  editValue.Text:='';
end;

end.
