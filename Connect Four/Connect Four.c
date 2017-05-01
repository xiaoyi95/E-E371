#include "system.h"
#include "sys/alt_stdio.h"
#include "stdbool.h"
#include "alt_types.h"
#include "altera_avalon_pio_regs.h"
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <math.h>


#define BOARD_WIDTH 7
#define BOARD_HEIGHT 7

volatile char * our_board_move_submit_ptr = (char *) OUR_BOARD_MOVE_SUBMIT_BASE;
volatile char * our_board_move_input_ptr = (char *) OUR_BOARD_MOVE_INPUT_PIO_BASE;
volatile char * transfer_data_ready_ptr = (char *) TRANSFER_DATA_READY_PIO_BASE;

volatile char * data_ready_clock = (char *) TRANSFER_DATA_READY_PIO_BASE;
volatile char * other_board_move_input_ptr = (char *) TRANSFER_DATA_PIO_BASE;

volatile char * our_turn_ptr = (char *) OUR_TURN_PIO_BASE;

volatile char * our_last_move_ptr = (char *) OUR_LAST_MOVE_PIO_BASE;
volatile char * submit_our_last_move_ptr = (char *) SUBMIT_OUR_LAST_MOVE_BASE;

volatile int8_t * wins_ptr = (int8_t  *) WINS_BASE;
volatile int8_t  * losses_ptr = (int8_t  *) LOSSES_BASE;
volatile int8_t  * ties_ptr = (int8_t  *) TIES_BASE;

volatile int32_t * red_led_0 = (int32_t *) RED_LED_0_BASE;
volatile int32_t * red_led_1 = (int32_t *) RED_LED_1_BASE;
volatile int32_t * green_led_0 = (int32_t *) GREEN_LED_0_BASE;
volatile int32_t * green_led_1 = (int32_t *) GREEN_LED_1_BASE;

bool transfer_data_ready_val;

void print_val(int val) {
	alt_putchar('0' + ((val / 10) % 10));
	alt_putchar('0' + (val % 10));
}

int get_input_from_other_board() {
	*our_turn_ptr = 0;
	while (1) {
		bool new_transfer_data_ready_val = (*transfer_data_ready_ptr) & 1;
		if (transfer_data_ready_val != new_transfer_data_ready_val) {
			transfer_data_ready_val = new_transfer_data_ready_val;
			alt_putstr("GOT INPUT FROM OTHER BOARD: ");
			print_val((*other_board_move_input_ptr) & 0x0F);
			alt_putchar('\n');
			return ((*other_board_move_input_ptr) & 0x0F); // Get the last 4 bits and return it
		}
	}
	*our_turn_ptr = 1;
}

int get_input_from_board() {
	while (1) {
		if ((*our_board_move_submit_ptr) & 1) {
			return ((*our_board_move_input_ptr) & 0x0F); // Get the last 4 bits and return it
		}
	}
}


int main()
{ 
	int games_won = 0;
	int games_lost = 0;
	int games_tied = 0;

  // 0 = nobody has played here, 1 = player 1 has played here, 2 = player 2 has played here
  unsigned char game_board [BOARD_WIDTH][BOARD_HEIGHT] = {{0}};

  transfer_data_ready_val = *transfer_data_ready_ptr;
  *submit_our_last_move_ptr = 0;


  bool we_are_player1 = (*((char *) WE_ARE_P1_PIO_BASE)) & 1;
  bool our_move = we_are_player1;

  *our_turn_ptr = our_move;

  bool we_started = we_are_player1;

  alt_putstr("Hello\n");

  *red_led_0 = 0;
  *red_led_1 = 0;
  *green_led_0 = 0;
  *green_led_1 = 0;

  while (1) {
	  int move_column;
	  int temp1, temp2;
	  if (our_move) {
		  alt_putstr("Your Move. Enter a column (on the board): ");
		  move_column = get_input_from_board();
		  temp1 = move_column;
		  alt_putstr("\nGot input from board: ");
		  alt_putchar('0' + (move_column % 10));
		  alt_putchar('\n');
	  } else { // It is their move
		  alt_putstr("Their Move. Enter a column (on other board): ");
		  move_column = get_input_from_other_board();
		  temp2 = move_column;
		  alt_putstr("Got Input from other board\n");
	  }

	  if(move_column == 7){
		  if(temp1 == 7){
			  alt_putstr("Game reset by us\n");
			  usleep(10000000);
			  *our_last_move_ptr = move_column & 0x0F;
			  *submit_our_last_move_ptr = !(*submit_our_last_move_ptr & 1);
			  temp1 = 0;
		  }else if(temp2 == 7){
			  alt_putstr("Game reset by other player\n");
			  temp2 = 0;
		  }

		  *red_led_0 = 0;
		  *red_led_1 = 0;
		  *green_led_0 = 0;
		  *green_led_1 = 0;

		  alt_putstr("Wins: ");
		  print_val(games_won);
		  alt_putstr(" Losses: ");
		  print_val(games_lost);
		  alt_putstr(" Ties: ");
		  print_val(games_tied);
		  alt_putstr("\n\n\n");
		  int g, h;
		  for (g = 0; g < BOARD_WIDTH; g++)
			  for (h = 0; h < BOARD_HEIGHT; h++)
				  game_board[g][h] = 0;
		  we_started = !we_started; // Switch who starts play
		  our_move = we_started;
		  *our_turn_ptr = our_move;

	  }else{
		  if (0 <= move_column && move_column < BOARD_WIDTH && // The input represents a valid column number
			  game_board[move_column][BOARD_HEIGHT - 1] == 0 /* The column is NOT full */ )
		  {
			  // The user has made a valid move, so we handle that move here

			  // Find what row the move should be registered at
			  int move_row = 0;
			  while (game_board[move_column][move_row] != 0 && move_row < 6) {
				  move_row++;
			  }

			  /*
			   * Determine what symbol we should insert into game_board
			   *
			   * our_move | we_are_player1 : decision
			   * 1        | 1              : 1
			   * 1        | 0              : 2
			   * 0        | 1              : 2
			   * 0        | 0              : 1
			   *
			   * This evaluates to the XOR (^) function
			   */
			  int insert_value = (our_move ^ we_are_player1) ? 2 : 1;

			  // Insert the move into the board
			  game_board[move_column][move_row] = insert_value;

			  // Check if the player who just moved won
			  bool player_won = false;
			  // Check horizontally, in positive direction

			  // check horizontally, in negative direction

			  // If the the game hasn't been won, check if the board is full
			  // Check horizontally
			  // This checks if there is any sequence of 4 in the row where a player just moved
			  int x;
			  for (x = 0; (x + 3) < BOARD_WIDTH; x++) {
				  if (game_board[x][move_row] == insert_value &&
					  game_board[x + 1][move_row] == insert_value &&
					  game_board[x + 2][move_row] == insert_value &&
					  game_board[x + 3][move_row] == insert_value)
				  {
					  player_won = true;
				  }
			  }
			  // Check vertically
			  if (!player_won) {
				  if (move_row - 3 >= 0 &&
					  game_board[move_column][move_row] == insert_value &&
					  game_board[move_column][move_row - 1] == insert_value &&
					  game_board[move_column][move_row - 2] == insert_value &&
					  game_board[move_column][move_row - 3] == insert_value)
				  {
					  player_won = true;
				  }
			  }

			  // check diagonal
			  // ascendingDiagonalCheck
			  int a, b;
			  for (a = 3; a < BOARD_WIDTH; a++){
				  for (b=0; b<BOARD_HEIGHT-3; b++){
					  if (game_board[a][b] == insert_value &&
						  game_board[a-1][b+1] == insert_value &&
						  game_board[a-2][b+2] == insert_value &&
						  game_board[a-3][b+3] == insert_value){
						  player_won = true;
					  }
				  }
			  }
			  // descendingDiagonalCheck
			  int c, d;
			  for (c = 3; c < BOARD_WIDTH; c++){
				  for (d=3; d<BOARD_HEIGHT; d++){
					  if (game_board[c][d] == insert_value &&
						  game_board[c-1][d-1] == insert_value &&
						  game_board[c-2][d-2] == insert_value &&
						  game_board[c-3][d-3] == insert_value){
						  player_won = true;
					  }
				  }
			  }

			  // Check if the board is full (Game is tied)
			  bool tied = true;
			  if (!player_won) {
				  int x;
				  for (x = 0; x < BOARD_WIDTH; x++) {
					  if (game_board[x][BOARD_HEIGHT - 1] == 0) {
						  tied = false;
						  break;
					  }
				  }
			  }

			  // Print the board
			  alt_putstr("GAME BOARD: \n");
			  alt_putstr("+-+-+-+-+-+-+-+\n");
			  int e, f;
			  for (f = BOARD_HEIGHT - 1; f >= 0; f--) {
				  alt_putchar('|');
				  for (e = BOARD_WIDTH - 1; e >= 0; e--) {
					  alt_putchar(game_board[e][f] == 0 ? ' ' : ('0' + game_board[e][f]));
					  alt_putchar('|');
				  }
				  alt_putstr("\n+-+-+-+-+-+-+-+\n");
			  }
			  alt_putstr(" 6 5 4 3 2 1 0 \n");


			  // Output the board data to verilog
			  int y;
			  for (y = 3; y >= 0; y--) {
				  for (x = 7; x >= 0; x--) {
					  if (x > BOARD_WIDTH - 1 || y > BOARD_HEIGHT - 1) {
						  *red_led_0 = (*red_led_0 << 1) | 0;
						  *green_led_0 = (*green_led_0 << 1) | 0;
					  } else {
						  *red_led_0 = ((*red_led_0) << 1) | (game_board[x][y] == 1);
						  *green_led_0 = ((*green_led_0) << 1) | (game_board[x][y] == 2);
					  }
				  }
			  }
			  // Upper rows
			  for (y = 7; y >= 4; y--) {
				  for (x = 7; x >= 0; x--) {
					  if (x > BOARD_WIDTH - 1 || y > BOARD_HEIGHT - 1) {
						  *red_led_1 = (*red_led_1 << 1) | 0;
						  *green_led_1 = (*green_led_1 << 1) | 0;
					  } else {
						  *red_led_1 = (*red_led_1 << 1) | (game_board[x][y] == 1);
						  *green_led_1 = (*green_led_1 << 1) | (game_board[x][y] == 2);
					  }
				  }
			  }


			  // Send the move that we made
			  if (our_move) {
				  *our_last_move_ptr = move_column & 0x0F;
				  *submit_our_last_move_ptr = !(*submit_our_last_move_ptr & 1);
			  }



			  if (player_won || tied) {
				  if (player_won) {
					  our_move ? games_won++ : games_lost++;
					  * wins_ptr = games_won;
					  * losses_ptr = games_lost;
					  alt_putstr(our_move ? "You Won\n" : "They Won\n");
				  }
				  else {
					  games_tied++;
					  * ties_ptr = games_tied;
				  }

				  alt_putstr("\nWins: ");
				  print_val(games_won);
				  alt_putstr(" Losses: ");
				  print_val(games_lost);
				  alt_putstr(" Ties: ");
				  print_val(games_tied);
				  alt_putchar('\n');


				  alt_putstr("Starting a new game.\n\n");

				  if (our_move && !we_started){
					  volatile int i;
					  for ( i = 0; i < 1000000; i++);
				  }
				  we_started = !we_started; // Switch who starts play
				  our_move = we_started;
				  *our_turn_ptr = our_move;


				  // Reset game_board
				  usleep(700000);
				  int g, h;
				  for (g = 0; g < BOARD_WIDTH; g++)
					  for (h = 0; h < BOARD_HEIGHT; h++)
						  game_board[g][h] = 0;

				  *red_led_0 = 0;
				  *red_led_1 = 0;
				  *green_led_0 = 0;
				  *green_led_1 = 0;

			  } else {
				  our_move = !our_move;
			  }



		  } else {
			  if (our_move) {
				  alt_putstr("You made an invalid move: ");
				  print_val(move_column);
				  alt_putchar('\n');
				  // Wait a little bit of time
				  volatile int i;
				  for (i = 0; i < 1000000; i++);
			  } else {
				  *our_last_move_ptr = 15;
				  *submit_our_last_move_ptr = !(*submit_our_last_move_ptr & 1);
			  }
		  }
	  }
  }

  return 0;
}
