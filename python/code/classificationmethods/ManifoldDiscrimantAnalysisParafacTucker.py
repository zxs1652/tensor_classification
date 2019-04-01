from abc import ABC, abstractmethod
import numpy as np
from scipy.stats import ortho_group  
from pymanopt import Problem
from pymanopt.manifolds import Product, Stiefel
import tensorflow as tf
from pymanopt.solvers import ConjugateGradient
from sklearn.pipeline import Pipeline

class ManifoldDiscrimantAnalysis(ABC,Pipeline):
    def __init__(self, classes, Us=None, opts=None, usestoppingcrit=True, maxits=1000,
                 store={'Rw': None, 'Rb': None, 'QtRb': None, 'QtRw':  None, 'QtBQ': None, 'QtWQ': None, 'QtWQinvQtBQ': None},
                 optmeth='ManOpt'):
        self.classes=classes
        self.Us=Us
        self.opts=opts
        self.usestoppingcrit=usestoppingcrit
        self.maxits=maxits
        self.store=store
        self.optmeth=optmeth
        if optmeth not in ['bo13', 'wen12', 'ManOpt']:
            self.optmeth='ManOpt'
            print("Chosen optimization method", optmeth, "has not been implemented")
        self.Fdifftol=Fdifftol=10**(-10)
        self.Udifftol=Udifftol=10**(-12)
        if Us==None:
            for i in range(self.nmodes):
                Us[i]=ortho_group.rvs(dim=(np.shape(self.sizeX)[i])) #Contemplate changing this
        self.MyCost=None
    def SetTolerances(self,Fdifftol=10**(-10), Udifftol=10**(-12)):
        self.Fdifftol=Fdifftol
        self.Udifftol=Udifftol
        
    @abstractmethod 
    def ObjectMatrixData(self, U,x, store, classmeandiffs, observationdiffs, nis, K1, K2,): #This is a virtual function that any inheriting subclass should realize
        return(None)
        
    @abstractmethod
    def QtCalculator(self):
        return(None)
    @abstractmethod
    def QtCheck(self):
        return(None)
        
    def my_cost(self, x, store, classmeandiffs, observationdiffs, nis, K1, K2, Rw, Rb):
        self.ObjectMatrixData(self,x, store, classmeandiffs, observationdiffs, nis, K1, K2)
        """
        self.F=-np.linalg.trace(self.store['QtWQinvQtBQ'])
        Q = tf.Variable(tf.placeholder(tf.float32))
        """

        self.MyCost = tf.linalg.trace(self.store['QtWQinvQtBQ'])

        #problem = Problem(manifold=manifold, cost=MyCost, arg=Q)

        """
        With tensorflow:
            Q=tf.Variable(tf.placeholder(tf.float32))
            self.MyCost=tf.linalg.trace(g(Q)) Operations to construct my cost inserted herein - potential to save a lot of calculations and definitions in the code when porting?
                    
            problem=Problem(manifold=manifold,cost=MyCost,arg=Q)
            
        """
        
    def ClassBasedDifferences(self,Xs,classes):
        """
        We should implement the classbased_differences method from the MATLAB code here.
        """
        nsamples = max(np.shape(Xs))
        nclasses = len(np.unique(classes))
        Xsum = np.sum(Xs, axis=0)
        Xmean = Xsum/nsamples
        Xsumsclasses=np.zeros((np.shape(Xs[0], nclasses)))
        Xmeansclasses=np.zeros((np.shape(Xs[0], nclasses)))
        enumerated_classes=range(nclasses)
        nis=np.zeros(nclasses)

        for i in range(nclasses):
            locations = np.nonzero(classes == i)
            nis[i] = len(locations)
            Xsumsclasses[i] = sum(Xs, locations)
            Xmeansclasses = Xsumsclasses[i]/nis[i]

        for i in range(nsamples): #This should be vectorized
            xi_m_cmeans = Xs[i]-Xmeansclasses[classes[i]]

        cmeans_m_xmeans = Xmeansclasses-Xmean
        return cmeans_m_xmeans, xi_m_cmeans, nis
    def CalculateYs(self):
        """
        Calculate Y
        """
        pass
    def OptimizeOnManifold(self,options):
        if self.optmeth=='ManOpt':
            ManifoldOne=Stiefel(np.shape(self.Us[0])[0],np.shape(self.Us[0])[1]) #This is hardcoding it to the two-dimensional case..
            ManifoldTwo=Stiefel(np.shape(self.Us[0])[0],np.shape(self.Us[0])[1])
            manifold=Product(ManifoldOne,ManifoldTwo)
            Q = tf.Variable(tf.placeholder(tf.Matrix))
            problem=Problem(manifold=manifold,cost=self.MyCost,arg=Q) #This assumes TensorFlow implementation... Else we have to implement the gradient and Hessian manually...
            solver=ConjugateGradient(problem, Q, options)
            return(solver)

    def fit(self, Xs, Ys, lowerdims=None):
        if lowerdims is None:
            self.lowerdims=np.size(Xs[0])
        Xsample1 = Xs[0];
        sizeX = np.shape(self.Xsample1);
        nmodes = len(self.sizeX);
        nsamples = np.shape(Xs);
        """
        The functions should be called in the order:
        The ObjectMatrixData function
        The MyCost funcction, 
        The optimize on manifold function
        These three together should give sufficient fit information to feed into a pipeline. 
        """


    def predict(self, Xs):
        pass


class TuckerDiscriminantAnalysis(ManifoldDiscrimantAnalysis):
    def QtCheck(self,Qt):
        if self.store[Qt]==None:
            self.store[Qt]=self.QtCalculator(Qt)
    def QtCalculator(self,Qt,N=None,K1=None,K2=None,U1=None,U2=None):
        U1=tf.Variable(tf.placeholder(tf.Matrix))
        U2=tf.Variable(tf.placeholder(tf.Matrix))
        if Qt in {'QtRw', 'QtRb'}:
            Qt_mm=tf.tensordot(tf.tensordot(self.Qt[-2:],tf.linalg.transpose(U1),axes=(1,0)),tf.linalg.transpose(U2),axes=(2,0)) #Something might be horribly wrong here...
            Qt_temp=tf.reshape(tf.roll(Qt_mm,(1,0,2))(K2*K1,N)) #Not sure if this is the correct approach. Need MATLAB license to test original behavior
        if Qt in {'QtWQ', 'QtBQ'}: #This ain't right
            Qt_temp=tf.matmul(self.store['QtRw'],self.store['QtRw'])
        if Qt in {'QtWQinvQtBQ'}:
            Qt_temp=tf.matmul(self.store['QtBQ'],tf.linalg.inv(self.store['QtWQ']))
        else:
            print("Wrong Qt specified")
        self.store[Qt]=Qt_temp
    def ObjectMatrixData(self, U, x, store, classmeandiffs, observationdiffs, nis, K1, K2):
        if (self.store['Rw']==[] or self.store['Rb']==[]):
            obsExample=classmeandiffs[0]
            sizeObs=np.shape(obsExample)
            I=sizeObs[0]
            J=sizeObs[1]
            if self.store['Rw']==0: #What if only one of them is missing? Shouldn't we still calculate the missing one? Split the code below into two parts, one for each case. This has been done now, but not in the MATLAB code
                nclasses=max(np.shape(classmeandiffs)) #This is a straight-copy of the existing MATLAB code, not sure if this is the intended behavior there either...
                classmeandiffstensor=np.reshape(classmeandiffs,(I,J,nclasses),order="F")
                Rb=classmeandiffstensor
            if self.store['Rb']==0:
                nobs=max(np.shape(observationdiffs))
                observationdiffstensor=np.reshape(observationdiffs,(I,J,nobs),order="F")
                Rw=observationdiffstensor
            self.store['Rw'] = Rw
            self.store['Rb'] = Rb
#        Rw=store['Rw'] #This assignment SHOULD be superflous now...
#        Rw=store['Rb']
        Rwsize = np.shape(Rw)
        nobs=Rwsize[-1]
        datadims=np.shape(Rb)
        nclasses=len(datadims)
        N=datadims[0] #This is a point where the two-dimensionality is hardcoded..
        M=datadims[1]
        #We proceed to calculate all relevant matrices for the optimization step. 
        for j in {'QtRw', 'QtRb', 'QtWQ', 'QtBQ', 'QtWQinvQtBQ', 'FdwrtQ'}:
            self.QtCheck(j)
        
        
class PARAFACDiscriminantAnalysis(ManifoldDiscrimantAnalysis):    
    def ObjectMatrixData(U, cmean_m_xmeans, xi_m_cmeans, nis, K1, K2):
        
        
        return()