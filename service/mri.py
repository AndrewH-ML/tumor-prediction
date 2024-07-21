#get current directory

cwd = os.getcwd()
path = os.path.dirname(cwd) + '/data/mri/'

im = np.array(Image.open(os.path.join(path, "yes/y0.jpg")).resize((200,200)))
plt.imshow(im)
plt.title("Tumor mri")
plt.show()
im = im/255.
im.shape

X = []
Y = []

for file in glob.glob(os.path.join(path, 'no/*.jpg')):
  im = np.array(Image.open(file).resize((200, 200)).convert('RGB'))
  X.append(im)
  Y.append(0)

for file in glob.glob(os.path.join(path, 'yes/*.jpg')):
  im = np.array(Image.open(file).resize((200, 200)).convert('RGB'))
  X.append(im)
  Y.append(1)

X = np.array(X)
Y = np.array(Y)

print("image data processed...")
print("X shape: ", X.shape)
print("Y shape: ", Y.shape, "\n")

#transform data
print("transforming data...")
X = X.reshape(X.shape[0], -1)
Y = Y.reshape(Y.shape[0], 1)
print("data reshaped...")
print("X shape: ", X.shape)
print("Y shape: ", Y.shape, "\n")

#standardize data
X = X/255.

print("splitting data...")
X_train, X_test, Y_train, Y_test = train_test_split(X, Y, train_size = .75 )
print("data split...")
print("X shape: ", X_train.shape)
print("Y shape: ", Y_train.shape, "\n")

X_train, X_test = X_train.T, X_test.T
Y_train, Y_test = Y_train.T, Y_test.T
print("X shape: ", X_train.shape)
print("Y shape: ", Y_train.shape)

layers_dims = [120000, 20, 7, 5, 3, 1] #  4-layer model

parameters, costs = neural_net.learn(X_train, Y_train, layers_dims, num_iterations = 1500)

predictions_train = neural_net.predict(X_test, Y_test, parameters)

iterations = range(1, len(costs) + 1)
plt.plot(iterations, costs)
plt.title('Cost over Iterations')
plt.xlabel('Iterations')
plt.ylabel('Cost')
plt.show()

print(np.shape(parameters))