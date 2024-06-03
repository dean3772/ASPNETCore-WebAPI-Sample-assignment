import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 50 }, // ramp up to 50 users over 2 minutes
    { duration: '3m', target: 50 }, // stay at 50 users for 3 minutes
    { duration: '2m', target: 0 },  // ramp down to 0 users over 2 minutes
  ],
};

export default function () {
  http.get('http://localhost:8080/swagger/index.html');
  sleep(1);
}
