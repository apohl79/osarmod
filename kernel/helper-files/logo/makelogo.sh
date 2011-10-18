#!/bin/sh
cat > x << __EOF__
#include <iostream>
#include "$1" //this is the logo, saved in gimp as "C header"
using namespace std;

int main( )
{
	int totalpixels = 480 * 800;
	int breakcount=1;
	cout << "const unsigned long LOGO_RGB24[] = {\n\t";
	for( int i = 0; i < totalpixels; i++ )
        {
		unsigned char pixel[6]="";
                HEADER_PIXEL(header_data,pixel);
		
		cout << "0x00";
		for (int j = 0; j <3 ; j++)
		{
			if ( pixel[j] < 16)
		   	cout << "0";	
			cout << std::hex << (int)pixel[j];
		}
			if ( breakcount == 10) {	
					breakcount = 1;
					cout << ",\n\t";
			}
			else {
					breakcount++;
					cout << ",";
			}
	}
	cout << "\n};\n\n";
	return 0;
}
__EOF__
g++ -o x -x c++ x >> /dev/null 2>&1;cat template > logo_rgb24_wvga_portrait.h;./x >> logo_rgb24_wvga_portrait.h;cat charging >> logo_rgb24_wvga_portrait.h;rm -f x
