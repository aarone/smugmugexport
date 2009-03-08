
struct MemHandleOpaque;

struct Array {
    unsigned int magic;
    unsigned int itemSize;
    unsigned int itemCount;
    int dataStored;
    int dataAllocated;
    int lockCount;
    struct MemHandleOpaque *itemsHandle;
    void *compareProc;
    unsigned char keepSorted;
    unsigned char isSorted;
};

struct MessageReceiver {
    unsigned int magic;
    unsigned int disableCount;
    unsigned int modificationCount;
    struct Array senders;
    void *handlerProc;
    void *handlerData;
};

struct IPPhotoInfo {
    void **_field1;
    id _field2;
    int _field3;
    struct SqPhotoInfo *_field4;
    unsigned int _field5;
    unsigned int _field6;
    struct IPRoll *_field7;
    struct IPStack *_field8;
    id _field9;
    id _field10;
    id _field11;
    int _field12;
    _Bool _field13;
    id _field14;
    unsigned char _field15;
    struct IPImage *_field16[6];
    unsigned long long _field17;
    char _field18;
    char _field19;
    unsigned long _field20;
    id _field21;
    id _field22;
    int _field23;
    id _field24;
    id _field25;
    _Bool _field26;
    char _field27;
    unsigned long _field28;
    unsigned long _field29;
    unsigned char _field30;
    unsigned int _field31;
    struct CGSize _field32;
    struct MessageReceiver _field33;
};