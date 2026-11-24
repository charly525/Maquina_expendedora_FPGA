-- =====================================================================
-- fuente_5x7.vhd  (GENERADO por gen_fuente.py, no editar a mano)
-- ROM de caracteres 5x7. Cada caracter ocupa 8 filas (la 8a vacia).
-- Codigos: 0-9 = digitos, 10-35 = A-Z, 36 = espacio, 37 = ':',
--          38 = '-', 39 = '!', 40 = '.', 41 = '#', 42 = '*'
-- bits(4) es la columna izquierda.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fuente_5x7 is
    port (
        codigo : in  std_logic_vector(5 downto 0);
        fila   : in  std_logic_vector(2 downto 0);
        bits   : out std_logic_vector(4 downto 0)
    );
end entity;

architecture rom of fuente_5x7 is
    signal dir : natural range 0 to 511;
begin
    dir <= to_integer(unsigned(codigo & fila));

    process(dir)
    begin
        case dir is
            when 0 => bits <= "01110";   -- '0' fila 0
            when 1 => bits <= "10001";   -- '0' fila 1
            when 2 => bits <= "10011";   -- '0' fila 2
            when 3 => bits <= "10101";   -- '0' fila 3
            when 4 => bits <= "11001";   -- '0' fila 4
            when 5 => bits <= "10001";   -- '0' fila 5
            when 6 => bits <= "01110";   -- '0' fila 6
            when 8 => bits <= "00100";   -- '1' fila 0
            when 9 => bits <= "01100";   -- '1' fila 1
            when 10 => bits <= "00100";   -- '1' fila 2
            when 11 => bits <= "00100";   -- '1' fila 3
            when 12 => bits <= "00100";   -- '1' fila 4
            when 13 => bits <= "00100";   -- '1' fila 5
            when 14 => bits <= "01110";   -- '1' fila 6
            when 16 => bits <= "01110";   -- '2' fila 0
            when 17 => bits <= "10001";   -- '2' fila 1
            when 18 => bits <= "00001";   -- '2' fila 2
            when 19 => bits <= "00010";   -- '2' fila 3
            when 20 => bits <= "00100";   -- '2' fila 4
            when 21 => bits <= "01000";   -- '2' fila 5
            when 22 => bits <= "11111";   -- '2' fila 6
            when 24 => bits <= "11111";   -- '3' fila 0
            when 25 => bits <= "00010";   -- '3' fila 1
            when 26 => bits <= "00100";   -- '3' fila 2
            when 27 => bits <= "00010";   -- '3' fila 3
            when 28 => bits <= "00001";   -- '3' fila 4
            when 29 => bits <= "10001";   -- '3' fila 5
            when 30 => bits <= "01110";   -- '3' fila 6
            when 32 => bits <= "00010";   -- '4' fila 0
            when 33 => bits <= "00110";   -- '4' fila 1
            when 34 => bits <= "01010";   -- '4' fila 2
            when 35 => bits <= "10010";   -- '4' fila 3
            when 36 => bits <= "11111";   -- '4' fila 4
            when 37 => bits <= "00010";   -- '4' fila 5
            when 38 => bits <= "00010";   -- '4' fila 6
            when 40 => bits <= "11111";   -- '5' fila 0
            when 41 => bits <= "10000";   -- '5' fila 1
            when 42 => bits <= "11110";   -- '5' fila 2
            when 43 => bits <= "00001";   -- '5' fila 3
            when 44 => bits <= "00001";   -- '5' fila 4
            when 45 => bits <= "10001";   -- '5' fila 5
            when 46 => bits <= "01110";   -- '5' fila 6
            when 48 => bits <= "00110";   -- '6' fila 0
            when 49 => bits <= "01000";   -- '6' fila 1
            when 50 => bits <= "10000";   -- '6' fila 2
            when 51 => bits <= "11110";   -- '6' fila 3
            when 52 => bits <= "10001";   -- '6' fila 4
            when 53 => bits <= "10001";   -- '6' fila 5
            when 54 => bits <= "01110";   -- '6' fila 6
            when 56 => bits <= "11111";   -- '7' fila 0
            when 57 => bits <= "00001";   -- '7' fila 1
            when 58 => bits <= "00010";   -- '7' fila 2
            when 59 => bits <= "00100";   -- '7' fila 3
            when 60 => bits <= "01000";   -- '7' fila 4
            when 61 => bits <= "01000";   -- '7' fila 5
            when 62 => bits <= "01000";   -- '7' fila 6
            when 64 => bits <= "01110";   -- '8' fila 0
            when 65 => bits <= "10001";   -- '8' fila 1
            when 66 => bits <= "10001";   -- '8' fila 2
            when 67 => bits <= "01110";   -- '8' fila 3
            when 68 => bits <= "10001";   -- '8' fila 4
            when 69 => bits <= "10001";   -- '8' fila 5
            when 70 => bits <= "01110";   -- '8' fila 6
            when 72 => bits <= "01110";   -- '9' fila 0
            when 73 => bits <= "10001";   -- '9' fila 1
            when 74 => bits <= "10001";   -- '9' fila 2
            when 75 => bits <= "01111";   -- '9' fila 3
            when 76 => bits <= "00001";   -- '9' fila 4
            when 77 => bits <= "00010";   -- '9' fila 5
            when 78 => bits <= "01100";   -- '9' fila 6
            when 80 => bits <= "01110";   -- 'A' fila 0
            when 81 => bits <= "10001";   -- 'A' fila 1
            when 82 => bits <= "10001";   -- 'A' fila 2
            when 83 => bits <= "11111";   -- 'A' fila 3
            when 84 => bits <= "10001";   -- 'A' fila 4
            when 85 => bits <= "10001";   -- 'A' fila 5
            when 86 => bits <= "10001";   -- 'A' fila 6
            when 88 => bits <= "11110";   -- 'B' fila 0
            when 89 => bits <= "10001";   -- 'B' fila 1
            when 90 => bits <= "10001";   -- 'B' fila 2
            when 91 => bits <= "11110";   -- 'B' fila 3
            when 92 => bits <= "10001";   -- 'B' fila 4
            when 93 => bits <= "10001";   -- 'B' fila 5
            when 94 => bits <= "11110";   -- 'B' fila 6
            when 96 => bits <= "01110";   -- 'C' fila 0
            when 97 => bits <= "10001";   -- 'C' fila 1
            when 98 => bits <= "10000";   -- 'C' fila 2
            when 99 => bits <= "10000";   -- 'C' fila 3
            when 100 => bits <= "10000";   -- 'C' fila 4
            when 101 => bits <= "10001";   -- 'C' fila 5
            when 102 => bits <= "01110";   -- 'C' fila 6
            when 104 => bits <= "11100";   -- 'D' fila 0
            when 105 => bits <= "10010";   -- 'D' fila 1
            when 106 => bits <= "10001";   -- 'D' fila 2
            when 107 => bits <= "10001";   -- 'D' fila 3
            when 108 => bits <= "10001";   -- 'D' fila 4
            when 109 => bits <= "10010";   -- 'D' fila 5
            when 110 => bits <= "11100";   -- 'D' fila 6
            when 112 => bits <= "11111";   -- 'E' fila 0
            when 113 => bits <= "10000";   -- 'E' fila 1
            when 114 => bits <= "10000";   -- 'E' fila 2
            when 115 => bits <= "11110";   -- 'E' fila 3
            when 116 => bits <= "10000";   -- 'E' fila 4
            when 117 => bits <= "10000";   -- 'E' fila 5
            when 118 => bits <= "11111";   -- 'E' fila 6
            when 120 => bits <= "11111";   -- 'F' fila 0
            when 121 => bits <= "10000";   -- 'F' fila 1
            when 122 => bits <= "10000";   -- 'F' fila 2
            when 123 => bits <= "11110";   -- 'F' fila 3
            when 124 => bits <= "10000";   -- 'F' fila 4
            when 125 => bits <= "10000";   -- 'F' fila 5
            when 126 => bits <= "10000";   -- 'F' fila 6
            when 128 => bits <= "01110";   -- 'G' fila 0
            when 129 => bits <= "10001";   -- 'G' fila 1
            when 130 => bits <= "10000";   -- 'G' fila 2
            when 131 => bits <= "10111";   -- 'G' fila 3
            when 132 => bits <= "10001";   -- 'G' fila 4
            when 133 => bits <= "10001";   -- 'G' fila 5
            when 134 => bits <= "01111";   -- 'G' fila 6
            when 136 => bits <= "10001";   -- 'H' fila 0
            when 137 => bits <= "10001";   -- 'H' fila 1
            when 138 => bits <= "10001";   -- 'H' fila 2
            when 139 => bits <= "11111";   -- 'H' fila 3
            when 140 => bits <= "10001";   -- 'H' fila 4
            when 141 => bits <= "10001";   -- 'H' fila 5
            when 142 => bits <= "10001";   -- 'H' fila 6
            when 144 => bits <= "01110";   -- 'I' fila 0
            when 145 => bits <= "00100";   -- 'I' fila 1
            when 146 => bits <= "00100";   -- 'I' fila 2
            when 147 => bits <= "00100";   -- 'I' fila 3
            when 148 => bits <= "00100";   -- 'I' fila 4
            when 149 => bits <= "00100";   -- 'I' fila 5
            when 150 => bits <= "01110";   -- 'I' fila 6
            when 152 => bits <= "00111";   -- 'J' fila 0
            when 153 => bits <= "00010";   -- 'J' fila 1
            when 154 => bits <= "00010";   -- 'J' fila 2
            when 155 => bits <= "00010";   -- 'J' fila 3
            when 156 => bits <= "00010";   -- 'J' fila 4
            when 157 => bits <= "10010";   -- 'J' fila 5
            when 158 => bits <= "01100";   -- 'J' fila 6
            when 160 => bits <= "10001";   -- 'K' fila 0
            when 161 => bits <= "10010";   -- 'K' fila 1
            when 162 => bits <= "10100";   -- 'K' fila 2
            when 163 => bits <= "11000";   -- 'K' fila 3
            when 164 => bits <= "10100";   -- 'K' fila 4
            when 165 => bits <= "10010";   -- 'K' fila 5
            when 166 => bits <= "10001";   -- 'K' fila 6
            when 168 => bits <= "10000";   -- 'L' fila 0
            when 169 => bits <= "10000";   -- 'L' fila 1
            when 170 => bits <= "10000";   -- 'L' fila 2
            when 171 => bits <= "10000";   -- 'L' fila 3
            when 172 => bits <= "10000";   -- 'L' fila 4
            when 173 => bits <= "10000";   -- 'L' fila 5
            when 174 => bits <= "11111";   -- 'L' fila 6
            when 176 => bits <= "10001";   -- 'M' fila 0
            when 177 => bits <= "11011";   -- 'M' fila 1
            when 178 => bits <= "10101";   -- 'M' fila 2
            when 179 => bits <= "10101";   -- 'M' fila 3
            when 180 => bits <= "10001";   -- 'M' fila 4
            when 181 => bits <= "10001";   -- 'M' fila 5
            when 182 => bits <= "10001";   -- 'M' fila 6
            when 184 => bits <= "10001";   -- 'N' fila 0
            when 185 => bits <= "10001";   -- 'N' fila 1
            when 186 => bits <= "11001";   -- 'N' fila 2
            when 187 => bits <= "10101";   -- 'N' fila 3
            when 188 => bits <= "10011";   -- 'N' fila 4
            when 189 => bits <= "10001";   -- 'N' fila 5
            when 190 => bits <= "10001";   -- 'N' fila 6
            when 192 => bits <= "01110";   -- 'O' fila 0
            when 193 => bits <= "10001";   -- 'O' fila 1
            when 194 => bits <= "10001";   -- 'O' fila 2
            when 195 => bits <= "10001";   -- 'O' fila 3
            when 196 => bits <= "10001";   -- 'O' fila 4
            when 197 => bits <= "10001";   -- 'O' fila 5
            when 198 => bits <= "01110";   -- 'O' fila 6
            when 200 => bits <= "11110";   -- 'P' fila 0
            when 201 => bits <= "10001";   -- 'P' fila 1
            when 202 => bits <= "10001";   -- 'P' fila 2
            when 203 => bits <= "11110";   -- 'P' fila 3
            when 204 => bits <= "10000";   -- 'P' fila 4
            when 205 => bits <= "10000";   -- 'P' fila 5
            when 206 => bits <= "10000";   -- 'P' fila 6
            when 208 => bits <= "01110";   -- 'Q' fila 0
            when 209 => bits <= "10001";   -- 'Q' fila 1
            when 210 => bits <= "10001";   -- 'Q' fila 2
            when 211 => bits <= "10001";   -- 'Q' fila 3
            when 212 => bits <= "10101";   -- 'Q' fila 4
            when 213 => bits <= "10010";   -- 'Q' fila 5
            when 214 => bits <= "01101";   -- 'Q' fila 6
            when 216 => bits <= "11110";   -- 'R' fila 0
            when 217 => bits <= "10001";   -- 'R' fila 1
            when 218 => bits <= "10001";   -- 'R' fila 2
            when 219 => bits <= "11110";   -- 'R' fila 3
            when 220 => bits <= "10100";   -- 'R' fila 4
            when 221 => bits <= "10010";   -- 'R' fila 5
            when 222 => bits <= "10001";   -- 'R' fila 6
            when 224 => bits <= "01111";   -- 'S' fila 0
            when 225 => bits <= "10000";   -- 'S' fila 1
            when 226 => bits <= "10000";   -- 'S' fila 2
            when 227 => bits <= "01110";   -- 'S' fila 3
            when 228 => bits <= "00001";   -- 'S' fila 4
            when 229 => bits <= "00001";   -- 'S' fila 5
            when 230 => bits <= "11110";   -- 'S' fila 6
            when 232 => bits <= "11111";   -- 'T' fila 0
            when 233 => bits <= "00100";   -- 'T' fila 1
            when 234 => bits <= "00100";   -- 'T' fila 2
            when 235 => bits <= "00100";   -- 'T' fila 3
            when 236 => bits <= "00100";   -- 'T' fila 4
            when 237 => bits <= "00100";   -- 'T' fila 5
            when 238 => bits <= "00100";   -- 'T' fila 6
            when 240 => bits <= "10001";   -- 'U' fila 0
            when 241 => bits <= "10001";   -- 'U' fila 1
            when 242 => bits <= "10001";   -- 'U' fila 2
            when 243 => bits <= "10001";   -- 'U' fila 3
            when 244 => bits <= "10001";   -- 'U' fila 4
            when 245 => bits <= "10001";   -- 'U' fila 5
            when 246 => bits <= "01110";   -- 'U' fila 6
            when 248 => bits <= "10001";   -- 'V' fila 0
            when 249 => bits <= "10001";   -- 'V' fila 1
            when 250 => bits <= "10001";   -- 'V' fila 2
            when 251 => bits <= "10001";   -- 'V' fila 3
            when 252 => bits <= "10001";   -- 'V' fila 4
            when 253 => bits <= "01010";   -- 'V' fila 5
            when 254 => bits <= "00100";   -- 'V' fila 6
            when 256 => bits <= "10001";   -- 'W' fila 0
            when 257 => bits <= "10001";   -- 'W' fila 1
            when 258 => bits <= "10001";   -- 'W' fila 2
            when 259 => bits <= "10101";   -- 'W' fila 3
            when 260 => bits <= "10101";   -- 'W' fila 4
            when 261 => bits <= "10101";   -- 'W' fila 5
            when 262 => bits <= "01010";   -- 'W' fila 6
            when 264 => bits <= "10001";   -- 'X' fila 0
            when 265 => bits <= "10001";   -- 'X' fila 1
            when 266 => bits <= "01010";   -- 'X' fila 2
            when 267 => bits <= "00100";   -- 'X' fila 3
            when 268 => bits <= "01010";   -- 'X' fila 4
            when 269 => bits <= "10001";   -- 'X' fila 5
            when 270 => bits <= "10001";   -- 'X' fila 6
            when 272 => bits <= "10001";   -- 'Y' fila 0
            when 273 => bits <= "10001";   -- 'Y' fila 1
            when 274 => bits <= "10001";   -- 'Y' fila 2
            when 275 => bits <= "01010";   -- 'Y' fila 3
            when 276 => bits <= "00100";   -- 'Y' fila 4
            when 277 => bits <= "00100";   -- 'Y' fila 5
            when 278 => bits <= "00100";   -- 'Y' fila 6
            when 280 => bits <= "11111";   -- 'Z' fila 0
            when 281 => bits <= "00001";   -- 'Z' fila 1
            when 282 => bits <= "00010";   -- 'Z' fila 2
            when 283 => bits <= "00100";   -- 'Z' fila 3
            when 284 => bits <= "01000";   -- 'Z' fila 4
            when 285 => bits <= "10000";   -- 'Z' fila 5
            when 286 => bits <= "11111";   -- 'Z' fila 6
            when 288 => bits <= "00000";   -- ' ' fila 0
            when 289 => bits <= "00000";   -- ' ' fila 1
            when 290 => bits <= "00000";   -- ' ' fila 2
            when 291 => bits <= "00000";   -- ' ' fila 3
            when 292 => bits <= "00000";   -- ' ' fila 4
            when 293 => bits <= "00000";   -- ' ' fila 5
            when 294 => bits <= "00000";   -- ' ' fila 6
            when 296 => bits <= "00000";   -- ':' fila 0
            when 297 => bits <= "01100";   -- ':' fila 1
            when 298 => bits <= "01100";   -- ':' fila 2
            when 299 => bits <= "00000";   -- ':' fila 3
            when 300 => bits <= "01100";   -- ':' fila 4
            when 301 => bits <= "01100";   -- ':' fila 5
            when 302 => bits <= "00000";   -- ':' fila 6
            when 304 => bits <= "00000";   -- '-' fila 0
            when 305 => bits <= "00000";   -- '-' fila 1
            when 306 => bits <= "00000";   -- '-' fila 2
            when 307 => bits <= "11111";   -- '-' fila 3
            when 308 => bits <= "00000";   -- '-' fila 4
            when 309 => bits <= "00000";   -- '-' fila 5
            when 310 => bits <= "00000";   -- '-' fila 6
            when 312 => bits <= "00100";   -- '!' fila 0
            when 313 => bits <= "00100";   -- '!' fila 1
            when 314 => bits <= "00100";   -- '!' fila 2
            when 315 => bits <= "00100";   -- '!' fila 3
            when 316 => bits <= "00100";   -- '!' fila 4
            when 317 => bits <= "00000";   -- '!' fila 5
            when 318 => bits <= "00100";   -- '!' fila 6
            when 320 => bits <= "00000";   -- '.' fila 0
            when 321 => bits <= "00000";   -- '.' fila 1
            when 322 => bits <= "00000";   -- '.' fila 2
            when 323 => bits <= "00000";   -- '.' fila 3
            when 324 => bits <= "00000";   -- '.' fila 4
            when 325 => bits <= "01100";   -- '.' fila 5
            when 326 => bits <= "01100";   -- '.' fila 6
            when 328 => bits <= "01010";   -- '#' fila 0
            when 329 => bits <= "01010";   -- '#' fila 1
            when 330 => bits <= "11111";   -- '#' fila 2
            when 331 => bits <= "01010";   -- '#' fila 3
            when 332 => bits <= "11111";   -- '#' fila 4
            when 333 => bits <= "01010";   -- '#' fila 5
            when 334 => bits <= "01010";   -- '#' fila 6
            when 336 => bits <= "00000";   -- '*' fila 0
            when 337 => bits <= "00100";   -- '*' fila 1
            when 338 => bits <= "10101";   -- '*' fila 2
            when 339 => bits <= "01110";   -- '*' fila 3
            when 340 => bits <= "10101";   -- '*' fila 4
            when 341 => bits <= "00100";   -- '*' fila 5
            when 342 => bits <= "00000";   -- '*' fila 6
            when others => bits <= "00000";
        end case;
    end process;
end architecture;
