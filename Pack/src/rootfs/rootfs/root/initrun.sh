#!/bin/sh

DAV_DIR=/dav

start()
{
        echo "This is initrun.sh start!!!!!!!!!!!!!!!!!!"

        #env
        ln -s $DAV_DIR/bin/* /bin/
        ln -s $DAV_DIR/lib/*.lib /lib/

        cd $DAV_DIR/modules/
        insmod rf433.ko

        TUAPP_BIN=`which tuapp`
        $TUAPP_BIN &

}

stop()
{
        echo "This is initrun.sh stop!!!!!!!!!!!!!!!!!!"

        rmmod rf433.ko
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  *)
        echo "Usage: $0 {start|stop}"
        exit 1
esac

exit $?