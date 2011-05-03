from rpy import *

# avoid automatic conversion
set_default_mode(NO_CONVERSION)


r.library("nnet")
model = r("Fxy~x+y")

df = r.data_frame(x = r.c(0,2,5,10,15)
                   ,y = r.c(0,2,5,8,10)
                   ,Fxy = r.c(0,2,5,8,10))

NNModel = r.nnet(model, data = df
                  , size =10, decay =1e-3
                  , lineout=True, skip=True
                  , maxit=1000, Hess =True)

XG = r.expand_grid(x = r.seq(0,7,1), y = r.seq(0,7,1))
x = r.seq(0,7,1)
y = r.seq(0,7,1)


# turn automatic conversion back on
set_default_mode(BASIC_CONVERSION)

fit = r.predict(NNModel,XG)
print fit

