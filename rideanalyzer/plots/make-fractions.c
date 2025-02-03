// The shell doesn't have floating point.

#include <stdio.h>

int main(int argc, char **argv) {


	for ( int i = 0; i < 60; i++ ) {
		float h = i / 60.0;
		printf("%0.4f ",h);
	}

}

