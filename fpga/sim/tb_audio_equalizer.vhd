library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_audio_equalizer is
end entity tb_audio_equalizer;
architecture sim of tb_audio_equalizer is
    constant CLK_PERIOD : time := 8 ns;
    constant FS : real := 24000.0;
    --UUT unit under test
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal en : std_logic := '0';
    signal en_lpf : std_logic := '0';
    signal en_bpf : std_logic := '0';
    signal en_hpf : std_logic := '0';
    signal din : std_logic_vector(11 downto 0) := X"800";
    signal dout : std_logic_vector(11 downto 0);
    signal sim_done : boolean := false;
begin
    -- Instantiate the audio equalizer
    uut: entity work.audio_equalizer
        port map (
            clk => clk,
            reset => reset,
            en => en,
            en_lpf => en_lpf,
            en_bpf => en_bpf,
            en_hpf => en_hpf,
            din => din,
            dout => dout
        );
    -- Clock generation
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    -- Stimulus process
    stim_proc: process
    procedure send_tone(freq_hz : in real;
              num_samples : in integer) is variable val_v : integer;
        begin
        -- Implementation of the send_tone procedure goes here
        for n in 0 to num_samples-1 loop
            val_v := 2048 + integer(1000.0 * sin(2.0 * MATH_PI * freq_hz * real(n) / FS));
        din <= std_logic_vector(to_unsigned(val_v, 12));
                wait until rising_edge(clk);
                en <= '1';
                wait until rising_edge(clk);
                en <= '0';

                wait until rising_edge(clk);
                wait until rising_edge(clk);
            end loop;
        end procedure send_tone;
    begin
        reset <= '1';
        wait for 50 ns;
        reset <= '0';
        -- Test 1 LPF
        en_bpf <= '0';
        en_hpf <= '0';
        en_lpf <= '1';
        send_tone(300.0, 350);
        send_tone(1500.0, 350);
        en_lpf <= '0';
    
        -- Test 2 BPF
        en_lpf <= '0';
        en_hpf <= '0';
        en_bpf <= '1';
        send_tone(1500.0, 350);
        send_tone(6000.0, 350);
        en_bpf <= '0';
    
        -- Test 3 HPF
        en_lpf <= '0';
        en_bpf <= '0';
        en_hpf <= '1';
        send_tone(6000.0, 350);
        send_tone(300.0, 350);
        en_hpf <= '0';

        sim_done <= true;
        wait;
    end process stim_proc;

end architecture sim;
