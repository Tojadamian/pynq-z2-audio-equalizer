library ieee;
use ieee.std_logic_1164.all;

entity btn_controller is
    generic (
        DEBOUNCE_CYCLES : integer := 2_500_000;
        INIT_STATE : std_logic := '1'
    );

    port (
        clk   : in std_logic;
        reset : in std_logic;
        btn_in : in std_logic;
        state_out : out std_logic
    );
end entity;

architecture rtl of btn_controller is
    signal btn_sync1 : std_logic := '0' ;
    signal btn_sync2 : std_logic := '0' ;
    signal btn_clean : std_logic := '0' ;
    signal btn_prev : std_logic := '0' ;
    signal db_cnt : integer range 0 to DEBOUNCE_CYCLES -1 := 0;
    signal toggle_reg : std_logic := INIT_STATE;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then 
                btn_sync1 <= '0';
                btn_sync2 <= '0';
                btn_clean <= '0';
                btn_prev <= '0';
                db_cnt <= 0;
                toggle_reg <= INIT_STATE;
            else
                btn_sync1 <= btn_in;
                btn_sync2 <= btn_sync1;
                if btn_sync2 = btn_clean then
                    db_cnt <= 0;
                else
                    if db_cnt = (DEBOUNCE_CYCLES - 1) then
                        btn_clean <= btn_sync2;
                        db_cnt <= 0;
                    else
                        db_cnt <= db_cnt + 1;
                    end if;
                end if;
                btn_prev <= btn_clean;
                if btn_clean = '1' and btn_prev = '0' then
                    toggle_reg <= not toggle_reg;
                end if;
            end if;
        end if;
    end process;
    
    state_out <= toggle_reg;

end architecture;