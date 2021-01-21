from flask import Flask, request, url_for
from prometheus_client import Counter, Histogram
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from prometheus_client import make_wsgi_app
import time

app=Flask(__name__)
c = Counter("my_page_visits", "Total number of times our page has been requested",['endpoint'])
h = Histogram('request_process_time', 'Description of histogram',['endpoint'])
data=[]

@app.route("/")
def index():
    start =time.time()
    str1=""
    #c.labels(url_for('index').count_exceptions()
    c.labels(url_for('index')).inc()
    allUrl=[url_for('test'),url_for('fetchData'),url_for('addData')]
    for ele in allUrl:
        str1 +=ele
        str1 +='\n'
    h.labels(url_for('index')).observe(time.time() - start)
    return str1


@app.route("/test")
def test():
    start = time.time()
    c.labels(url_for('test')).inc()
    h.labels(url_for('test')).observe(time.time() - start)
    return "hI DS! Welcome Back"

@app.route("/data")
def fetchData():
    start =time.time()
    str1="{ "
    c.labels(url_for('fetchData')).inc()
    for ele in data:
        str1 += ele
        str1 += ","
    str1 += " }"
    h.labels(url_for('fetchData')).observe(time.time() -start)
    return str1

@app.route("/submit", methods = ['POST'])
def addData():
    start =time.time()
    c.labels(url_for('addData')).inc()

    if request.method == 'POST':
        fname=request.form['fname']
        lname=request.form['lname']
        email=request.form['E-mail']
        tempDict='{"First Name":'+fname+',"Last Name":'+lname+', "Email":'+email+'}'
        data.append(tempDict)
    else:
        return None
    h.labels(url_for('addData')).observe(time.time() - start)
    return "Data Added"


app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

if __name__=="__main__":
    app.run(host='0.0.0.0', port=5000)
