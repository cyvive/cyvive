#!/bin/bash
MAX=$1
case  1:${MAX:--} in
(1:*[!0-9]*|1:0*[89]*)
  ! echo NAN
;;
($((MAX<81))*)
	SIZING="c5"
;;
($((MAX<101))*)
	SIZING="c6"
;;
($((MAX<121))*)
	SIZING="C7"
;;
($((MAX<301))*)
	SIZING="c8"
;;
esac

echo $SIZING
