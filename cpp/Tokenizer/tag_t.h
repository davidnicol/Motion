

/* the tag type, which is *char so we can output them easily, but which might change if we need 
   to sort them, or group them efficiently, or whatever.
   */

#ifndef tag_t_h
#define tag_t_h
   
typedef const char *tag_t;

#define TAG_TO_STRING(t) ((char*) t )

extern tag_t TagWhiteSpace;
extern tag_t TagEndOfStream;
extern tag_t TagBeginStream;
extern tag_t TagSymbol;
extern tag_t TagBoundary;

#endif
