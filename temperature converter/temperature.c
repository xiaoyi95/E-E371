#include <stdio.h>
#include <stdbool.h>

bool includes(char unit);

int main(void){
    float temperature = 0.0;
    float celsius = 0.0;
    float fahrenheit = 0.0;
    float kelvin = 0.0;
    char unit = 'a';
    char decision = 'a';

    do{
        unit = 'a';
        while (!includes(unit)){
            printf("What unit do you want for the temperature value? \n");
            printf("Enter: 'F' for Fahrenheit, 'C' for Celsius, 'K' for Kelvin. \n");
            unit = getche();
            printf("\n");
        }

        printf("What is the temperature under the unit specified above? \n");
        scanf("%f",&temperature);

        //Calculate for the amount after conversion and print
        if(unit == 'f' || unit == 'F'){
            fahrenheit = temperature;
            celsius = (fahrenheit - 32) / 1.8;
            kelvin = celsius + 273;
            printf ("The temperature in Fahrenheit is: %f = %.2f\n", fahrenheit, fahrenheit);
            printf ("The temperature in Celsius is: (%.2f - 32 )/ 1.8 = %.2f\n", fahrenheit, celsius);
            printf ("The temperature in Kelvin is: %.2f + 273 = %.2f\n", celsius, kelvin);
        }else if (unit == 'c' || unit == 'C'){
            celsius = temperature;
            fahrenheit = 1.8 * celsius + 32;
            kelvin = celsius + 273;
            printf ("The temperature in Fahrenheit is: 1.8 * %f + 32 = %.2f\n", celsius, fahrenheit);
            printf ("The temperature in Celsius is: %f = %.2f\n", celsius, celsius);
            printf ("The temperature in Kelvin is: %.2f + 273 = %.2f\n", celsius, kelvin);
        }else if (unit =='k' || unit == 'K'){
            kelvin = temperature;
            celsius = kelvin - 273;
            fahrenheit = 1.8 * celsius + 32;
            printf ("The temperature in Fahrenheit is: 1.8 * %.2f + 32 = %.2f\n", celsius, fahrenheit);
            printf ("The temperature in Celsius is: %.2f -273 = %.2f\n", kelvin, celsius);
            printf ("The temperature in Kelvin is: %f = %.2f\n", kelvin, kelvin);
        }

        printf ("\n");
        printf ("Continue? Y for Yes / Other characters for No\n");
        decision = getche();
        printf("\n\n");
    } while(decision == 'Y' || decision == 'y');

    return 0;
}


// Helper Method
bool includes(char unit){
    char units[6] = {'c', 'C', 'f','F','k', 'K'};
    int i;
    for(i = 0; i < 6; i++){
        if(units[i] == unit){
            return true;
        }
    }
    return false;
}
