unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, GStack,
  Menus, ComCtrls, ExtCtrls;

type
  TintegerStack = specialize TStack<integer>;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Image1: TImage;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ScrollBox1: TScrollBox;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton6Click(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
    procedure DibujaKarel(x: integer;  y: integer; sentido: integer);
    procedure DibujaMundo();
    procedure Inicializa();
    procedure Avanza();
    procedure GiraIzquierda();
    procedure AnalizaSemantico(instrucciones : TStringList);
    procedure lexico();
    procedure sintactico();
    procedure semantico();
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  n : integer; // número de estados (empieza de 0)
  qi, qf : integer; // qi:estado inicial  qf:estado final
  alfabeto : String;
  tablaT, mundo : array of array of integer; // Cambiar de forma dinámica la Tabla de Transiciones
  x_pos, y_pos, sentido, sem_pos, dis_cuadricula , offset_cuadricula:integer;//posiciones del robot .
  arraySemantico : TStringList;
  row, col, x_pos_array, y_pos_array : integer;
  ancho, alto : integer;
  lexi, sintac, choque : boolean;

implementation

{$R *.lfm}

{ TForm1 }


//Funciones del analizador léxico
type
  stringArray = array of string;

function esPalabraReservada(token : string) : boolean;
var
  reservadoArray : stringArray;
  i : integer;
begin
  //busca palabras reservadas
reservadoArray := stringArray.create('programa','inicio','cargar_laberinto','avanza','vuelta_izquierda',
               'frente_libre', 'izquierda_libre', 'repetir', 'veces', 'mientras', 'si', 'fin', '(', ')', 'n', ';');
result := false;
for i := low(reservadoArray) to high(reservadoArray) do
  if token = reservadoArray[i] then
    begin
      result := true;
    end;
end;

function esSimbolo(token : string) : boolean;
var
  simbolosArray : stringArray;
  i : integer;
begin
  //busca palabras reservadas
simbolosArray := stringArray.create('#','+','-','*');
result := false;
for i := low(simbolosArray) to high(simbolosArray) do
  if token = simbolosArray[i] then
    begin
      result := true;
    end;
end;

function noEsSeparador(c : char) : boolean;
var
  expresion : boolean;
begin
  expresion := ((c <> ' ') and (c <> chr(9)) and (c <> chr(13)) and (c <> chr(10)) and (c <> ';') and (c <> '(') and (c <> ')'));
  result := expresion and not esSimbolo(c);
end;

function esNumero(token : string) : boolean;
var
  num : Double;
begin
  //busca numeros
  result := false;
  if(TryStrToFloat(token, num)) then
    begin
      result := true;
    end;
end;

function esIdentificador(token : string) : integer;
const
  alfabeto = ['a'..'z', 'A'..'Z'];
  digitos = ['0' .. '9'];
var
  j : integer;
  letra : char;
begin
  //busca identificadores
  j := 1;
  result := 0;
  if j < length(token) then
    begin
      //si el primer caracter es letra, lo demás no puede ser simbolo
      if token[j] in alfabeto then
        begin
          for letra in token do
            begin
              if (not (token[j] in digitos)) and (not (token[j] in alfabeto)) then
                exit(5);
              inc(j);
            end;
          result := 3;
        end;
      //si el primer numero lo demás no puede ser caracter o simbolo
      if token[j] in digitos then
        begin
           for letra in token do
            begin
              if not (token[j] in digitos) then
                exit(4);
              inc(j);
            end;
          result := 3;
        end;
    end;
    if (j = length(token)) and (token[j] in alfabeto) then
      exit(3);
  end;

function analizaToken(token : string) : integer;
begin
if esPalabraReservada(token) then
  exit(1);

if esNumero(token) then
  exit(2);

if esSimbolo(token) then
  exit(6);

exit(esIdentificador(token));

result := 0;
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
   Memo1.Clear;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.Image1Click(Sender: TObject);
begin

end;

procedure TForm1.lexico();
var
  caracter : char;
  i, j, k, tamano, d : integer;
  token, tokenAux, tipo, tipoTokenAux, linea, texto : string;
  archivo_salida : TextFile;
begin
  lexi:=true;
  //asignar archivo
  AssignFile(archivo_salida, 'salida.txt');
  ReWrite(archivo_salida);
  i := 0;
  //read(f,caracter);
  //leer caracter por caracter y guardar en caracter
  d := Memo1.Lines.count-1;
  for j:=0 to d do begin
    linea := Memo1.Lines[j];
    linea := StringReplace(linea , #0, '', [rfReplaceAll]);
    k:=0;
    tamano:=linea.Length;
    while k<=tamano do begin
      inc(k);
      caracter := linea[k];
      //Análisis léxico
      token := '';
      tipo := '';
      tipoTokenAux := '';
      while (noEsSeparador(caracter)) and (k<=tamano) do begin
            token:= token + caracter;
            inc(k);
            caracter := linea[k];
      end;
      tokenaux := caracter;

      case analizaToken(token) of
           1 : tipo := 'palabra reservada';
           2 : tipo := 'numero';
           3 : tipo := 'identificador';
           4 : tipo := 'error, un identificador no puede iniciar con un numero';
           5 : tipo := 'error, simbolo no especificado dentro de identificador';
           6 : tipo := 'simbolo';
      end;

      if((tokenaux=';') and (token='')) or ((tokenaux=')') and (token='')) then
        begin
          texto:= tokenaux;
          WriteLn(archivo_salida, texto);
        end;

      if (esPalabraReservada(token)) or esNumero(token) then
        begin
            texto:= token;
            WriteLn(archivo_salida, texto);
            if (tokenaux = ';') or (tokenaux = '(') or (tokenaux = ')') then
            begin
              WriteLn(archivo_salida, tokenaux);
            end;
        end
      else
      begin
        if token <> '' then
        begin
          ShowMessage('Compilación errónea, palabra no identificada como parte del lenguaje');
          lexi:=false;
          exit();
        end;
      end;
    end;
  end;
  CloseFile(archivo_salida);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
lexico();
end;

function busqueda(caracter:char):integer;
var
   i, tam : integer;
   encontrado : boolean;
begin
   alfabeto := 'abcdefghijklmnopqrstuvwxyz';
   tam:=length(alfabeto);
   encontrado:=false;
   i:=1;
   while ((i<=tam) and (not encontrado)) do begin
       if (caracter=alfabeto[i]) then
          encontrado:=true;
       inc(i);
   end;
   if encontrado then begin
      dec(i);
      busqueda:=i-1;
   end
   else
      busqueda:=-1;
end;

function buscaString(cadena_entrada : string): integer;
var
   i : integer;
   encontrado : boolean;
begin


end;

function leerAutomata() : integer;
var
  fa, fe : TextFile;
  i, j, lalf : integer;
begin
  AssignFile(fa, 'automata.txt');
  AssignFile(fe, 'alfabeto.txt');
  reset(fa);
  reset(fe);

  read(fe, alfabeto);
  read(fa, n);
  lalf := 19 - 1;
  SetLength(tablaT, n+1, lalf+1);
  for i:=0 to n do begin
      for j:=0 to lalf do begin
          read(fa, tablaT[i, j]);
      end;
      readln(fa);
  end;
  qi := 0;
  readln(fa, qf);

  CloseFile(fa);
  CloseFile(fe);

end;

function asignarClavesTokens() : integer;
const
  alfabeto = 'abcdefghijklmnopqrstuvwxyz';
var
  archivo_salida, archivo_entrada_sintactico : TextFile;
  cadena : string;
  i : integer;
  letra : char;
  encontrado : boolean;
  ordenArray : stringArray;
begin
//leer el archivo de tokens e ingresar los datos al array con los números correspon
//dientes
  AssignFile(archivo_salida, 'salida.txt');
  AssignFile(archivo_entrada_sintactico, 'entrada_sintactico.txt');
  reset(archivo_salida);
  ReWrite(archivo_entrada_sintactico);

  ordenArray := stringArray.create('programa','inicio','fin',';','',
               'avanza', 'vuelta_izquierda', 'cargar_laberinto', 'repetir', 'veces',
               'mientras', 'si', 'frente_libre', 'izquierda_libre', 'y', 'o', 'n',
               '(', ')');

  while not eof(archivo_salida) do
    begin
      encontrado := false;
      ReadLn(archivo_salida, cadena);
      //buscar en el arreglo
      i:=0;
      if esNumero(cadena) then
         begin
            encontrado := true;
            i :=5;
         end;
      while encontrado = false do
       begin
         if cadena = ordenArray[i] then
         begin
            encontrado := true;
         end;
         inc(i);
       end;
      WriteLn(archivo_entrada_sintactico, alfabeto[i]);
    end;
  CloseFile(archivo_salida);
  CloseFile(archivo_entrada_sintactico);

end;

procedure TForm1.sintactico();
var
  entrada : String;
  i, j, k, estado_pasado : integer;
  band : boolean;
  letra : char;
  archivo_entrada_sintactico, archivo_salida_lexico : TextFile;
  pilaestado: tintegerStack;
begin
  sintac:=true;
  leerAutomata();
  asignarClavesTokens();
  //entrada := Edit1.Text;
  //inicializa pila
  pilaestado:= tintegerStack.create;
  //obtener la entrada del análisis sintáctico
  AssignFile(archivo_entrada_sintactico, 'entrada_sintactico.txt');
  AssignFile(archivo_salida_lexico, 'salida.txt');
  reset(archivo_salida_lexico);
  reset(archivo_entrada_sintactico);
  i:=qi;
  k:=1;
  band:=false;
  while ((not eof(archivo_entrada_sintactico)) and (not band)) do begin
     ReadLn(archivo_entrada_sintactico, letra);
     if letra = 'b' then
        pilaestado.push(1)
     else
     begin
       if letra = 'c' then begin
          if pilaestado.size > 0 then
             pilaestado.pop
          else
              begin
                 ShowMessage('Compilación errónea');
                 band:=true;
              end;
          end;
     end;

     j:=busqueda(letra);
     if (j>=0) then
     begin
        estado_pasado:=i;
        i:=tablaT[i,j];
        if i < 0 then
        begin
           band:=true;
        end;
     end
     else
        band:=true;
  end;
  if ((i=qf) and (not band) and (pilaestado.size=0)) then
     ShowMessage('Pasó el Análisis Sintáctico')
  else
     ShowMessage('NO pasó el Análisis Sintáctico. Revisa tu código');
  sintac:=(not band);

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  sintactico();
end;

procedure TForm1.DibujaKarel(x: integer;  y: integer; sentido: integer);
var
   x1, x2, x3, y1, y2, y3: integer;
begin
   // Dibujamos a Karel
   DibujaMundo();
   Image1.Canvas.Pen.Color := clBlack;
   Image1.Canvas.Brush.Color := clGreen;
   if (sentido = 4) then begin
      x1 := x - 8;
      y1 := y + 8;
      x2 := x - 8;
      y2 := y - 8;
      x3 := x + 16;
      y3 := y;
      Image1.Canvas.Polygon([point(x1,y1), point(x2,y2), point(x3,y3), point(x1,y1)]);
      Form1.Update;
      sleep(1000);
   end;
    if (sentido = 3) then begin
      x1 := x + 8;
      y1 := y - 8;
      x2 := x + 8;
      y2 := y + 8;
      x3 := x - 16;
      y3 := y;
      Image1.Canvas.Polygon([point(x1,y1), point(x2,y2), point(x3,y3), point(x1,y1)]);
      Form1.Update;
      sleep(1000);
   end;
    if (sentido = 2) then begin
      x1 := x - 8;
      y1 := y - 8;
      x2 := x + 8;
      y2 := y - 8;
      x3 := x;
      y3 := y + 16;
      Image1.Canvas.Polygon([point(x1,y1), point(x2,y2), point(x3,y3), point(x1,y1)]);
      Form1.Update;
      sleep(1000);
   end;
    if (sentido = 1) then begin
      x1 := x + 8;
      y1 := y + 8;
      x2 := x - 8;
      y2 := y + 8;
      x3 := x;
      y3 := y - 16;
      Image1.Canvas.Polygon([point(x1,y1), point(x2,y2), point(x3,y3), point(x1,y1)]);
      Form1.Update;
      sleep(1000);
   end;
end;

function leerLaberinto(num_laberinto : integer) : boolean;
var
   i, j : integer;
   laberinto : TextFile;
   resultado : boolean;
   n_lab : string;
begin
  col:=15;
  row:=15;
  //leer laberinto
  if (num_laberinto = 0) or (num_laberinto>16) then
     AssignFile(laberinto, 'laberinto.txt')
  else begin
     n_lab:='laberintos/' + inttostr(num_laberinto) + '.txt';
     AssignFile(laberinto, n_lab);
     end;
  Reset(laberinto);
  SetLength(mundo, row, col);
  for i:=0 to row -1 do
   begin
     for j:=0 to col -1 do
      begin
        Read(laberinto, mundo[i,j]);
      end;
     ReadLn(laberinto);
   end;
  closefile(laberinto);
  result:=true;
end;

function posRobot() : integer;
begin
  //calcular los indices del bicho
  x_pos_array:=(((x_pos-offset_cuadricula) div dis_cuadricula)-1);
  y_pos_array:=(((y_pos-offset_cuadricula) div dis_cuadricula)-1);

  if(mundo[y_pos_array, x_pos_array] = 0) then
  begin
     ShowMessage('karen ha chocado');
     choque:=true;
  end
  else if (y_pos_array = row-1) and (x_pos_array=col-1) then
  begin
     ShowMessage('karen ha ganado');
     choque:=true;
  end;
end;

procedure TForm1.Inicializa();
begin
  choque:=false;
  sentido:=2;
  dis_cuadricula:=30;
  offset_cuadricula:=15;
  alto:=510;
  ancho:=510;
  x_pos:=dis_cuadricula+offset_cuadricula;
  y_pos:=dis_cuadricula+offset_cuadricula;
  leerLaberinto(0);
  DibujaMundo();
  Form1.Update;
  posRobot();
end;

procedure TForm1.DibujaMundo();
var
     anchoIm, altoIm, margenIm, x, y, i,j: integer;
     x1,x2,y1,y2 : integer;
begin
    anchoIm := ancho;
    altoIm := alto;
    margenIm := dis_cuadricula;
    Image1.Width := anchoIm;
    Image1.Height := altoIm;
    Image1.Canvas.Pen.Color := clBlack;
    Image1.Canvas.Brush.Color := clWhite;
    Image1.Canvas.Rectangle(0, 0, anchoIm, altoIm);

    x := margenIm;
    y := margenIm;
    while (x <= anchoIm-margenIm) do begin
       Image1.Canvas.MoveTo(x, margenIm);
       Image1.Canvas.LineTo(x, altoIm - margenIm);
       inc(x, dis_cuadricula);
    end;

    while (y <= altoIm-margenIm) do begin
       Image1.Canvas.MoveTo(margenIm, y);
       Image1.Canvas.LineTo(anchoIm - margenIm, y);
       inc(y, dis_cuadricula);
    end;

    Image1.Canvas.Pen.Color := clBlack;
    Image1.Canvas.Brush.Color := clBlack;
    for i:=0 to row-1 do
     begin
       for j:=0 to col-1 do
        begin
          if mundo[i,j] = 0 then
          begin
            x1:=dis_cuadricula*j+dis_cuadricula;
            y1:=dis_cuadricula*i+dis_cuadricula;
            Image1.Canvas.Rectangle(x1, y1, x1+dis_cuadricula, y1+dis_cuadricula);
          end;
          if (i=row-1) and (j=col-1) then
          begin
            x1:=dis_cuadricula*j+dis_cuadricula;
            y1:=dis_cuadricula*i+dis_cuadricula;
            Image1.Canvas.Pen.Color := clRed;
            Image1.Canvas.Brush.Color := clRed;
            Image1.Canvas.Rectangle(x1, y1, x1+dis_cuadricula, y1+dis_cuadricula);
          end;
        end;
     end;
end;

procedure TForm1.Avanza();
begin
  if (sentido=1) then
  begin
    dec(y_pos, dis_cuadricula);
    Form1.DibujaKarel(x_pos, y_pos, sentido);
  end;
  if (sentido=2) then
  begin
    inc(y_pos, dis_cuadricula);
    Form1.DibujaKarel(x_pos, y_pos, sentido);
  end;
  if (sentido=3) then
  begin
    dec(x_pos, dis_cuadricula);
    Form1.DibujaKarel(x_pos, y_pos, sentido);
  end;
  if (sentido=4) then
  begin
    inc(x_pos, dis_cuadricula);
    Form1.DibujaKarel(x_pos, y_pos, sentido);
  end;
end;

procedure TForm1.GiraIzquierda();
begin
  case sentido of
       1: begin
         sentido:=3;
         DibujaKarel(x_pos, y_pos, sentido);
       end;
       2: begin
         sentido:=4;
         DibujaKarel(x_pos, y_pos, sentido)
       end;
       3: begin
         sentido:=2;
         DibujaKarel(x_pos, y_pos, sentido)
       end;
       4: begin
         sentido:=1;
         DibujaKarel(x_pos, y_pos, sentido)
       end;
  end;
end;

function crearSubList(listaoriginal : TStringList; inicio, fin : integer) : TStringList;
var
     lista : TStringList;
     i : integer;
begin
  lista := TStringList.Create;
  for i:= inicio to fin do
   begin
     lista.add(listaoriginal[i]);
   end;
  result:=lista;

end;

function frente_libre() : boolean;
var
     anchoIm, altoIm, margenIm : integer;
     libre : boolean;
begin
  posRobot();
  anchoIm := ancho;
  altoIm := alto;
  margenIm := dis_cuadricula;
  case sentido of
       1: begin  //arriba
         if ((y_pos - dis_cuadricula) < margenIm) then
         begin
            ShowMessage('frente NO libre');
            libre:=false;
            end
         else
         begin
           if (y_pos_array-1 >= 0) then
            begin
              if (mundo[y_pos_array-1, x_pos_array] = 0) then
              begin
                ShowMessage('frente NO libre');
                libre:=false;
              end
              else
              begin
                ShowMessage('frente libre');
                libre:=true;
              end;
            end
            else
            begin
              ShowMessage('frente libre');
              libre:=true;
            end;
         end;

       end;
       2: begin //abajo
         if ((y_pos+dis_cuadricula) > (altoIm-dis_cuadricula)) then
         begin
           ShowMessage('frente NO libre');
           libre:=false;
         end
         else
         begin
           if(y_pos_array+1 < row) then
            begin
              if mundo[y_pos_array+1,x_pos_array] = 0 then
              begin
                ShowMessage('frente NO libre');
                libre:=false;
              end
              else
              begin
                ShowMessage('frente libre');
                libre:=true;
              end;
            end
           else
           begin
             ShowMessage('Camino obstruido');
             libre:=true;
           end;
         end;
       end;
       3: begin //izquierda
         if (x_pos-dis_cuadricula) > (margenIm) then
         begin
           if (x_pos_array-1 >= 0) then
             begin
               if mundo[y_pos_array, x_pos_array-1] = 0 then
                 begin
                   ShowMessage('frente NO libre');
                   libre:=false;
                 end
               else
               begin
               ShowMessage('frente libre');
               libre:=true;
               end;

             end
         end
         else
         begin
           ShowMessage('frente NO libre');
           libre:=false;

         end;
       end;
       4: begin  //derecha
         if (x_pos+dis_cuadricula) < (anchoIm) then
         begin
           if (x_pos_array +1 < col) then
               begin
                 if (mundo[y_pos_array, x_pos_array+1] = 0) then
                    begin
                      ShowMessage('frente NO libre');
                      libre:=false;
                    end
                 else
                 begin
                    //ShowMessage('frente libre');
                    libre:=true;
                 end;
               end;
         end
         else
         begin
            ShowMessage('frente NO libre');
            libre:=false;
         end

       end;
  end;
  result:=libre;
end;

function izquierda_libre() : boolean;
var
     anchoIm, altoIm, margenIm : integer;
     libre : boolean;
begin
  anchoIm := ancho;
  altoIm := alto;
  margenIm := dis_cuadricula;
  posRobot();
  case sentido of
       1: begin //arriba
         if (x_pos - dis_cuadricula) < margenIm +dis_cuadricula then
         begin
            ShowMessage('izquierda NO libre');
            libre:=false;
            end
         else
         begin
            if(x_pos_array-1 >=0)  then
            begin
              if(mundo[y_pos_array, x_pos_array-1] = 0) then
              begin
                ShowMessage('izquierda NO libre');
                libre:=false;
              end
              else
              begin
                ShowMessage('izquierda libre');
                libre:=true;
              end;
            end
            else
            begin
              ShowMessage('izquierda NO libre');
              libre:=false;
            end;
         end;
       end;
       2: begin //abajo
         if (x_pos+dis_cuadricula) > (anchoIm-dis_cuadricula) then
         begin
            ShowMessage('izquierda NO libre');
            libre:=false;
         end
         else
         begin
           if (x_pos_array + 1 < col ) then
           begin
             if(mundo[y_pos_array, x_pos_array+1]=0) then
             begin
               ShowMessage('izquierda NO libre');
               libre:=false;
             end
             else
             begin
               ShowMessage('izquierda libre');
               libre:=true;
             end;
           end
           else
           begin
           ShowMessage('izquierda NO libre');
           libre:=false;
           end
         end;
       end;
       3: begin //izquierda
         if (y_pos+dis_cuadricula) > (altoIm-dis_cuadricula) then
         begin
            if(y_pos_array+1 < row) then
            begin
              if(mundo[y_pos_array+1, x_pos_array] = 0 ) then
              begin
                ShowMessage('izquierda NO libre');
                libre:=false;
              end
              else
              begin
              ShowMessage('izquierda libre');
              libre:=true;
              end;
            end
            else
            begin
            ShowMessage('izquierda NO libre');
            libre:=true;
            end;
         end
         else
         begin
           ShowMessage('izquierda NO libre');
           libre:=false;
         end;
       end;
       4: begin //derecha
         if (y_pos-dis_cuadricula) < (margenIm+dis_cuadricula) then
         begin
            if(y_pos_array -1 >= 0) then
            begin
               if(mundo[y_pos_array-1, x_pos_array] = 0) then
               begin
                  ShowMessage('izquierda NO libre');
                  libre:=false;
               end
               else
               begin
                    ShowMessage('izquierda libre');
                    libre:=true;
               end;
            end
            else
            begin
              ShowMessage('izquierda NO libre');
              libre:=false;
            end;
         end
         else
         begin
           ShowMessage('izquierda NO libre');
           libre:=false;
         end;
       end;
  end;
  result:=libre;
end;

procedure TForm1.AnalizaSemantico(instrucciones : TStringList);
var
     n_inicio, fin_pos, pos, new_pos,inicio_for, i : integer;
     cadena, numero_for, expresionb : string;
     subinstrucciones : TStringList;
     resultado_bool, negacion : boolean;
begin
  pos:=0;
  cadena:=instrucciones[pos];
  negacion:=false;
  while(pos < instrucciones.count) and (not choque) do
   begin
     case cadena of
       'avanza': begin
                 Avanza();
       end;
       'vuelta_izquierda' : begin
              GiraIzquierda();
       end;
       'si' : begin
              n_inicio:=0;
              inc(pos);
              inc(pos);
              expresionb:=instrucciones[pos];
              if (expresionb = 'n') then
              begin
                 negacion:=true;
                 inc(pos);
                 inc(pos);
                 expresionb:=instrucciones[pos];
              end;
              inc(pos);
              inc(pos);
              inc(n_inicio);
              new_pos:=pos;
              while(n_inicio <> 0) do
               begin
                 inc(new_pos);
                 cadena:=instrucciones[new_pos];
                 if cadena = 'inicio' then
                    inc(n_inicio)
                 else if cadena = 'fin' then
                    dec(n_inicio);
               end;
               subinstrucciones:=crearsublist(instrucciones, pos, new_pos);

               pos:=new_pos;
              case expresionb of
                   'frente_libre' : begin
                     resultado_bool := frente_libre();
                     resultado_bool := resultado_bool xor negacion;
                     if resultado_bool then
                     begin
                        AnalizaSemantico(subinstrucciones);
                     end;
                   end;

                   'izquierda_libre' : begin
                     resultado_bool := izquierda_libre();
                     resultado_bool := resultado_bool xor negacion;
                     if resultado_bool then
                     begin
                        AnalizaSemantico(subinstrucciones);
                     end;
                   end;

              end;

       end;
       'repetir' : begin
              inc(pos);
              numero_for:=instrucciones[pos];
              inc(pos);
              inc(pos);
              n_inicio:=0;
              inc(n_inicio);
              new_pos:=pos;
              while(n_inicio <> 0) do
               begin
                 inc(new_pos);
                 cadena:=instrucciones[new_pos];
                 if cadena = 'inicio' then
                    inc(n_inicio)
                 else if cadena = 'fin' then
                    dec(n_inicio);
               end;
               subinstrucciones:=crearsublist(instrucciones, pos, new_pos);
               i:=0;
              while(i<strtoint(numero_for)) and not choque do
               begin
                 AnalizaSemantico(subinstrucciones);
                 inc(i);
               end;
              pos:=new_pos;
       end;
       'mientras' : begin
         inc(pos);
         inc(pos);
         expresionb:=instrucciones[pos];
         if (expresionb = 'n') then
              begin
                 negacion:=true;
                 inc(pos);
                 inc(pos);
                 expresionb:=instrucciones[pos];
              end;
         inc(pos);
         inc(pos);
         n_inicio:=0;
         inc(n_inicio);
         new_pos:=pos;
         while(n_inicio <> 0) and not choque do
         begin
           inc(new_pos);
           cadena:=instrucciones[new_pos];
           if cadena = 'inicio' then
              inc(n_inicio)
           else if cadena = 'fin' then
                dec(n_inicio);
         end;
         subinstrucciones:=crearsublist(instrucciones, pos, new_pos);
         case expresionb of
                   'frente_libre' : begin
                     resultado_bool := frente_libre();
                     resultado_bool := resultado_bool xor negacion;
                     while resultado_bool do
                     begin
                        AnalizaSemantico(subinstrucciones);
                        resultado_bool := frente_libre();
                     end;
                   end;

                   'izquierda_libre' : begin
                     resultado_bool := izquierda_libre();
                     resultado_bool := resultado_bool xor negacion;
                     while resultado_bool do
                     begin
                        AnalizaSemantico(subinstrucciones);
                        resultado_bool := izquierda_libre();
                     end;
                   end;
              end;
         pos:=new_pos;
       end;
       'cargar_laberinto' : begin
         inc(pos);
         inc(pos);
         numero_for:=instrucciones[pos];
         inc(pos);
         inc(pos);
         //cargar laberinto según el número
         leerlaberinto(strtoint(numero_for));
         DibujaMundo();
         DibujaKarel(x_pos, y_pos, sentido);
       end;
     end;
     inc(pos);
     if(pos < instrucciones.count) then
     begin
       cadena:=instrucciones[pos];
     end;
     posRobot();
   end;
end;

procedure TForm1.Semantico();
var
    anchoIm, altoIm, margenIm, x, y, i, j,act_pos: integer;
    archivo_salida_lexico : TextFile;
    cadena : string;
begin
    //Dibuja mundo
    Inicializa();
    sentido:=4;
    DibujaKarel(x_pos, y_pos, sentido);
    sem_pos:=0;

    //abrir archivo para moverse en el mundo
    //analisis semántico
    arraySemantico := TStringList.Create;
    arraySemantico.LoadFromFile('salida.txt');
    cadena:=arraySemantico[sem_pos];
    AnalizaSemantico(arraySemantico);

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
    semantico();
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  //ejecucion completa.
  lexico();
  if lexi then
     sintactico();
  if sintac then
     semantico();
end;




procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Memo1.Lines.LoadFromFile(OpenDialog1.FileName);
  end;
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    Memo1.Lines.SaveToFile(OpenDialog1.FileName);
  end;
end;

procedure TForm1.MenuItem6Click(Sender: TObject);
begin
   Memo1.Undo;
end;

procedure TForm1.MenuItem7Click(Sender: TObject);
begin
  Memo1.CutToClipboard;
end;

procedure TForm1.MenuItem8Click(Sender: TObject);
begin
  Memo1.CopyToClipboard;
end;

procedure TForm1.MenuItem9Click(Sender: TObject);
begin
  Memo1.PasteFromClipboard;
end;

procedure TForm1.ToolButton5Click(Sender: TObject);
begin
  Memo1.CutToClipboard;
end;

procedure TForm1.ToolButton6Click(Sender: TObject);
begin
  Memo1.CopyToClipboard;
end;

procedure TForm1.ToolButton7Click(Sender: TObject);
begin
  Memo1.PasteFromClipboard;
end;

end.

