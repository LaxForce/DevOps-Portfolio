print('Starting MongoDB initialization script...');

db = db.getSiblingDB('admin');
print('Authenticating as root user...');
db.auth(process.env.MONGO_INITDB_ROOT_USERNAME, process.env.MONGO_INITDB_ROOT_PASSWORD)

print('Switching to application database...');
db = db.getSiblingDB(process.env.MONGO_INITDB_DATABASE);

print('Creating application user...');
db.createUser({
  user: process.env.MONGO_USERNAME,
  pwd: process.env.MONGO_PASSWORD,
  roles: [
    {
      role: "readWrite",
      db: process.env.MONGO_INITDB_DATABASE
    }
  ]
});

print('Creating initial collections...');
db.createCollection('contacts');

print('MongoDB initialization completed.');
