This system simulates a game called Connect Four and it made use of RS-232 to build a two-way communication channel between two boards so that the game can be played by two players.
The system simulates a game Connect Four (wikipedia.org/wiki/Connect_Four). Two players take turns to drop discs to a 7×7 grid. The discs drop from the top of the grid and land on top of the other discs in the column.
The game is won when a player has 4 of their own discs in a line diagonally, vertically, or horizontally. 
If the board is completely filled with nobody winning, then it is a tie. 
When a game is over, we empty the board and keep track of who won or lost. 
In this system, we use a 7×7 LED matrix (displayed on an 8x8 LED matrix) to simulate the grid and two different colors to represent two players. We also display the board in the eclipse console. The Eclipse console is used as a referee to instruct if it’s player’s turn to make next move or the winner of the game and also print out the grid each time one player makes a move. In the eclipse console we use number 1 and number 2 to represent two different players. 

