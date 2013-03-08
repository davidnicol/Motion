
HEADERS = tag_t.h fundamental.h switcheroos.h currenttoken.h
OBJS = tag_t.o main.o TSMO.o switcheroos.o currenttoken.o
CXX = g++
DEBUG = -g
CXXFLAGS = -Wall $(DEBUG) -c
LFLAGS = -Wall $(DEBUG)
	
tokenizer: $(OBJS)
	$(CXX) $(LFLAGS) -o tokenizer $(OBJS)

TSMO.o: $(HEADERS) TSMO.c
	$(CXX) $(CXXFLAGS) TSMO.c
	
currenttoken.o: $(HEADERS) currenttoken.c
	$(CXX) $(CXXFLAGS) currenttoken.c

switcheroos.o: $(HEADERS) switcheroos.c
	$(CXX) $(CXXFLAGS) switcheroos.c

tag_t.o: tag_t.h tag_t.c
	$(CXX) $(CXXFLAGS) tag_t.c

main.o: main.c $(HEADERS)
	$(CXX) $(CXXFLAGS) main.c

clean:
	rm *.o tokenizer



	

	
