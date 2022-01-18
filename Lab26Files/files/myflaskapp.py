from flask import Flask

app = Flask(__name__)

@app.route('/')
def welcome():
    return "<span style='color:red'>Welcome to flask application</span>"

@app.route('/test')
def test():
    return "This is test route of myapp flask application"