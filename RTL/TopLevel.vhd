library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--ENTITY AND PORTMAP FIRST--
entity TopLevel is
	port(
		topCLK  : in std_logic;
		uart_rxTop : in std_logic;
		doneLED : out std_logic;
		rxOutLED: out std_logic_vector(7 downto 0);
		
		vga_color : out std_logic_vector(11 downto 0);
		hsync, vsync : out std_logic
	);
end TopLevel;

--BEGIN "PRE"-ARCH AFTER PORTMAP--
architecture Behavioral of TopLevel is

--COMPONENTS HERE--
component uart_rx
   generic(
      DBIT: integer:= 8;     -- # data bits
      SB_TICK: integer:= 16  -- # ticks for stop bits
   );
   port(
      clk, reset: in std_logic;
      rx: in std_logic;
      s_tick: in std_logic;
      rx_done_tick: out std_logic_vector(0 downto 0);
      dout: out std_logic_vector(7 downto 0)

   );
end component;

component mod_m_counter 
   generic(
      N: integer := 4;     -- number of bits
      M: integer := 10     -- mod-M
  );
   port(
      clk, reset: in std_logic;
      max_tick: out std_logic;
      q: out std_logic_vector(N-1 downto 0)

   );
end component;

component blockram 
	port (
	clka: IN std_logic;
	wea: IN std_logic_VECTOR(0 downto 0);
	addra: IN std_logic_VECTOR(15 downto 0);
	dina: IN std_logic_VECTOR(7 downto 0);
	clkb: IN std_logic;
	addrb: IN std_logic_VECTOR(15 downto 0);
	doutb: OUT std_logic_VECTOR(7 downto 0));
END component;

component vga_sync
   port(
      clk, reset: in std_logic;
      hsync, vsync: out std_logic;
      video_on, p_tick: out std_logic;
      pixel_x, pixel_y: out std_logic_vector (9 downto 0)
    );
end component;

--SIGNALS HERE--
signal s_tickTOP: std_logic;
signal qHolder: std_logic_vector(7 downto 0); --7 is N-1
signal dtckToWea: std_logic_vector(0 downto 0);
signal rxOutToDina: std_logic_vector(7 downto 0);
--signal slower_clk: std_logic;

--	VGA SIGNALS
signal pixel_counter : std_logic;
signal hpixel_count   : integer;
signal vpixel_count   : integer;
signal COLOR_DISPLAY : std_logic;

signal Display_color : std_logic_vector(11 downto 0);
signal pixel_x : std_logic_vector(9 downto 0);
signal pixel_y : std_logic_vector(9 downto 0);
--END VGA SIGNALS

--FAKE SIGNALS HERE--
signal writeAddra: unsigned(15 downto 0) := "0000000000000000"; 
signal writeAddra_next: unsigned(15 downto 0) := "0000000000000000"; 
signal blockRAMInput: std_logic_vector(7 downto 0);
signal FAKEaddrb: std_logic_vector(15 downto 0);
signal FAKEdoutb: std_logic_vector(7 downto 0);
--BEGIN ACTUAL ARCH AFTER SIGNALS--
begin

RS_232: uart_rx
	generic map(DBIT=>8, SB_TICK=>16)
	port map (clk=>topCLK, reset=>'0', rx=>uart_rxTop, s_tick=>s_tickTOP, rx_done_tick=>dtckToWea, dout=>blockRAMInput);

count: mod_m_counter
	generic map(N=>8, M=>163)
	port map(clk=>topCLK, reset=>'0', max_tick=>s_tickTOP, q=>qHolder);
	
blkmem: blockram
	port map(clka=>s_tickTop, wea=>dtckToWea, addra=>std_logic_vector(writeAddra), dina=>blockRAMInput, clkb=>topCLK, addrb=>FAKEaddrb, doutb=>FAKEdoutb);

			--WHEN VIDEO ON SEND COLOR DATA
			--p_tick counts pixels horizontally	

			--WHEN COLOR_DISPLAY IS '1' US pixel_counter as a clock
			--COUNT to 640
			--WHEN COLOR_DISPLAY is '0' RESET pixel_counter
VGAOUT : vga_sync
   PORT MAP(
      clk=>topCLK , reset =>'0', 
      hsync => hsync, vsync => vsync, 
      video_on => COLOR_DISPLAY, p_tick => pixel_counter,
      pixel_x =>pixel_x, pixel_y => pixel_y);
	
process(topCLK)
   begin
		if (topCLK'event and topCLK='1') then
         writeAddra <= writeAddra_next;
      end if;
   end process;
process( dtckToWea, writeAddra)
begin
if (dtckToWea = "1") then
	writeAddra_next <= writeAddra +1;
 else
	writeAddra_next <= writeAddra;
end if;
end process;

--BLOCKRAM ADDRESS EQUATION (x-160) + 200(y-121)- 1;

process(topCLK,COLOR_DISPLAY, PIXEL_COUNTER)
begin
if (hpixel_count > 160 AND hpixel_count < 360 AND vpixel_count>120 AND vpixel_count<320) then 
	FAKEaddrb <= std_logic_vector(to_signed(((hpixel_count - 160) + (200 * (vpixel_count -121)) -1 ), 16));
	Display_color <= FAKEdoutb(7 downto 4) & FAKEdoutb(7 downto 4)& FAKEdoutb(7 downto 4);
	--Display_color <= "0000"&blockRAMInput;
else
	Display_color <= "000000000000";
end if;
end process;

rxOutLED <= blockRAMInput;--std_logic_vector(writeAddra(7 downto 0));
vga_color<=Display_color;
vpixel_count<= to_integer(signed(pixel_y));
hpixel_count<= to_integer(signed(pixel_x));

end Behavioral;
